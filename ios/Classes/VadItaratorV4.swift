import Foundation
import onnxruntime_objc

class VadIteratorV4: VadIterator{
    let sampleRate: Int64
    let frameSize: Int64
    let threshold: Float
    let minSilenceSamples: Int64
    let speechPadSamples: Int64
    let windowSizeSamples: Int64

    var triggerd: Bool = false
    var tempEnd: Int64 = 0
    var currentSample: Int64 = 0

    var hidden: [[[Float]]]
    var cell: [[[Float]]]
    let hcSize: Int = 2 * 1 * 64

    private var env: ORTEnv
    private var session: ORTSession

    init(
        modelPath: String, sampleRate: Int64, frameSize: Int64, threshold: Float,
        minSilenceDurationMs: Int64, speechPadMs: Int64)
    {
        self.sampleRate = sampleRate
        let srPerMs = sampleRate / 1000
        self.frameSize = frameSize
        self.threshold = threshold
        self.minSilenceSamples = srPerMs * minSilenceDurationMs
        self.speechPadSamples = srPerMs * speechPadMs
        self.windowSizeSamples = frameSize * srPerMs
        self.hidden = Array(
            repeating: Array(repeating: Array(repeating: Float(0.0), count: 64), count: 1), count: 2)
        self.cell = Array(
            repeating: Array(repeating: Array(repeating: Float(0.0), count: 64), count: 1), count: 2)
        self.env = try! ORTEnv(loggingLevel: .warning)
        let sessionOptions = try! ORTSessionOptions()
        try! sessionOptions.setIntraOpNumThreads(1)
        try! sessionOptions.setGraphOptimizationLevel(.all)
        self.session = try! ORTSession(
            env: env, modelPath: modelPath, sessionOptions: sessionOptions)
    }

    func resetState() {
        triggerd = false
        tempEnd = 0
        currentSample = 0
        hidden = Array(
            repeating: Array(repeating: Array(repeating: Float(0.0), count: 64), count: 1), count: 2)
        cell = Array(
            repeating: Array(repeating: Array(repeating: Float(0.0), count: 64), count: 1), count: 2)
    }

    func predict(data: [Float]) throws -> Bool {
        let inputShape: [NSNumber] = [1, NSNumber(value: windowSizeSamples)]
        let inputTensor = try ORTValue(
            tensorData: NSMutableData(
                bytes: data, length: Int(windowSizeSamples) * MemoryLayout<Float>.size),
            elementType: .float,
            shape: inputShape)
        let srTensor = try ORTValue(
            tensorData: NSMutableData(bytes: [sampleRate], length: MemoryLayout<Int64>.size),
            elementType: .int64,
            shape: [1])
        let hTensor = try ORTValue(
            tensorData: NSMutableData(bytes: hidden.flatMap { $0.flatMap { $0 } }, length: hcSize * MemoryLayout<Float>.size),
            elementType: .float,
            shape: [2, 1, 64])
        let cTensor = try ORTValue(
            tensorData: NSMutableData(bytes: cell.flatMap { $0.flatMap { $0 } }, length: hcSize * MemoryLayout<Float>.size),
            elementType: .float,
            shape: [2, 1, 64])

        let outputTensor = try session.run(
            withInputs: ["input": inputTensor, "sr": srTensor, "h": hTensor, "c": cTensor],
            outputNames: ["output", "hn", "cn"],
            runOptions: nil)
        guard let outputValue = outputTensor["output"],
              let hiddenValue = outputTensor["hn"],
              let cellValue = outputTensor["cn"]
        else {
            throw NSError(domain: "VadIterator", code: 1, userInfo: nil)
        }

        let outputData = try outputValue.tensorData() as Data
        let output = outputData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Float in
            let floatBuffer = buffer.bindMemory(to: Float.self)
            return floatBuffer[0]
        }

        let hc_shape = (2, 1, 64)

        let hiddenData = try hiddenValue.tensorData() as Data
        hiddenData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            let floatBuffer = buffer.bindMemory(to: Float.self)
            for i in 0..<hc_shape.0 {
                for j in 0..<hc_shape.1 {
                    for k in 0..<hc_shape.2 {
                        hidden[i][j][k] = floatBuffer[i * hc_shape.1 * hc_shape.2 + j * hc_shape.2 + k]
                    }
                }
            }
        }

        let cellData = try cellValue.tensorData() as Data
        cellData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            let floatBuffer = buffer.bindMemory(to: Float.self)
            for i in 0..<hc_shape.0 {
                for j in 0..<hc_shape.1 {
                    for k in 0..<hc_shape.2 {
                        cell[i][j][k] = floatBuffer[i * hc_shape.1 * hc_shape.2 + j * hc_shape.2 + k]
                    }
                }
            }
        }

        currentSample += windowSizeSamples

        if output >= threshold && tempEnd != 0 {
            tempEnd = 0
        }

        if output >= threshold && !triggerd {
            triggerd = true
        }

        if output < threshold - 0.15 && triggerd {
            if tempEnd == 0 {
                tempEnd = currentSample
            }

            if currentSample - tempEnd >= minSilenceSamples {
                triggerd = false
                tempEnd = 0
            }
        }

        return triggerd
    }
}
