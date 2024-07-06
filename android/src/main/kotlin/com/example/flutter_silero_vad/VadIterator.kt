package com.example.flutter_silero_vad;

interface VadIterator {
    fun predict(data: FloatArray): Boolean
    fun resetState()
}