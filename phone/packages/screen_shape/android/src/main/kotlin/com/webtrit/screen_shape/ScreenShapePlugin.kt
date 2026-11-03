package com.webtrit.screen_shape

import android.content.Context

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reports whether the display is round, as the maker declares it in the device configuration.
 * `Configuration.isScreenRound` exists since API 23, below the app's minimum.
 */
class ScreenShapePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_IS_ROUND -> result.success(context.resources.configuration.isScreenRound)
            else -> result.notImplemented()
        }
    }

    private companion object {
        const val METHOD_CHANNEL_NAME = "screen_shape"
        const val METHOD_IS_ROUND = "isRound"
    }
}
