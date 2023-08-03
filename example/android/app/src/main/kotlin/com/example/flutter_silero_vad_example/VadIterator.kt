package com.example.flutter_silero_vad_example

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession

import java.nio.FloatBuffer
import java.nio.LongBuffer
import java.util.Collections

class VadIterator constructor(
    modelPath: String,
    sampleRate: Long,
    frameSize: Long,
    threshold: Float,
    minSilenceDurationMs: Long,
    speechPadMs: Long
) {
    // model config

    private val sampleRate: Long
    private val frameSize: Long
    private val threshold: Float
    private val minSilenceSamples: Long
    private val speechPadSamples: Long

    /** surpport 256 512 768 for 8k; 512 1024 1536 for 16k */
    private val windowSizeSamples: Long

    // model states
    private var triggerd: Boolean = false
    private var tempEnd: Long = 0
    private var currentSample: Long = 0

    // model inputs
    private var hidden: Array<Array<FloatArray>>
    private var cell: Array<Array<FloatArray>>

    init {
        this.threshold = threshold;
        this.sampleRate = sampleRate;
        val srPerMs = sampleRate / 1000;
        this.frameSize = frameSize;
        this.minSilenceSamples = srPerMs * minSilenceDurationMs;
        this.speechPadSamples = srPerMs * speechPadMs;
        this.windowSizeSamples = frameSize * srPerMs;
        this.hidden = Array(2) { Array(1) { FloatArray(64) } };
        this.cell = Array(2) { Array(1) { FloatArray(64) } };

        initSession(modelPath);
    }

    private lateinit var env: OrtEnvironment;
    private lateinit var session: OrtSession;


    private fun initSession(modelPath: String) {
        env = OrtEnvironment.getEnvironment();
        val sessionOptions = OrtSession.SessionOptions();
        sessionOptions.setIntraOpNumThreads(1);
        sessionOptions.setInterOpNumThreads(1);
        sessionOptions.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT);
        session = env.createSession(modelPath, sessionOptions);
    }

    public fun resetState() {
        triggerd = false;
        tempEnd = 0;
        currentSample = 0;
        hidden = Array(2) { Array(1) { FloatArray(64) } };
        cell = Array(2) { Array(1) { FloatArray(64) } };
    }


    public fun predict(data: FloatArray): Boolean {
        var result = false;
        val inputOrt =
            OnnxTensor.createTensor(env, FloatBuffer.wrap(data), longArrayOf(1, windowSizeSamples));
        val srOrt = OnnxTensor.createTensor(
            env, sampleRate
        );
        val hOrt = OnnxTensor.createTensor(env, hidden);
        val cOrt = OnnxTensor.createTensor(env, cell);
        val outputOrt = session.run(
            mapOf(
                "input" to inputOrt,
                "sr" to srOrt,
                "h" to hOrt,
                "c" to cOrt,
            )
        );
        val output = (outputOrt[0].value as Array<FloatArray>
            ?: throw Exception("Unexpected output type"))[0][0];
        hidden = outputOrt[1].value as Array<Array<FloatArray>>;
        cell = outputOrt[2].value as Array<Array<FloatArray>>;

        currentSample += windowSizeSamples;

        if (output >= threshold && tempEnd != 0.toLong()) {
            tempEnd = 0
        }

        if (output >= threshold && !triggerd) {
            triggerd = true
        }

        if (output < (threshold - 0.15) && triggerd) {
            if (tempEnd == 0.toLong()) {
                tempEnd = currentSample
            }

            if (currentSample - tempEnd >= minSilenceSamples) {
                triggerd = false
                tempEnd = 0
            }
        }
        return triggerd;
    }
}