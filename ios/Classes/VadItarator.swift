import Foundation
import onnxruntime_objc

protocol VadIterator {
    func resetState()
    func predict(data: [Float]) throws -> Bool
} 
