package com.example.flutter_silero_vad_example

import androidx.annotation.NonNull

import com.example.flutter_silero_vad_example.VadIterator

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterSileroVadPlugin */
class FlutterSileroVadPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var vad: VadIterator

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_silero_vad")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> {
                vad = VadIterator(
                    call.argument<String>("modelPath")!!,
                    call.argument<Long>("sampleRate")!!,
                    call.argument<Long>("frameSize")!!,
                    call.argument<Float>("threshold")!!,
                    call.argument<Long>("minSilenceDurationMs")!!,
                    call.argument<Long>("speechPadMs")!!
                )
                result.success("vad initialized")
            }

            "predict" -> {
                val data = call.argument<FloatArray>("data")!!
                val res = vad.predict(data)
                result.success(res)
            }

            "resetState" -> {
                vad.resetState()
                result.success("vad reset state")
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
