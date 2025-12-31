package com.bruno.system_theme

import android.R
import android.app.Activity
import android.content.Context
import android.content.res.Configuration
import android.util.TypedValue
import android.view.ContextThemeWrapper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class SystemThemePlugin: FlutterPlugin, ActivityAware, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var activity: Activity

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "system_theme")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    when (call.method) {
        "SystemTheme.accentColor" -> {
          val color = getDeviceAccentColor(activity)
          val r = (color shr 16) and 0xFF
          val g = (color shr 8) and 0xFF
          val b = color and 0xFF
          // val a = (color shr 24) and 0xFF 

          result.success(hashMapOf<String, Any?>(
              "accent" to hashMapOf<String, Any?>(
                  "R" to r,
                  "G" to g,
                  "B" to b,
                  "A" to 255
              )
          ))
        }
        else -> {
          result.notImplemented()
        }
    }
  }

  private fun getDeviceAccentColor(context: Context) : Int {
    val value = TypedValue()
    val ctx = ContextThemeWrapper(context, R.style.Theme_DeviceDefault)
    ctx.theme.resolveAttribute(android.R.attr.colorAccent, value, true)
    return value.data
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {}

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
      activity = binding.activity
  }

  override fun onDetachedFromActivity() {}

}
