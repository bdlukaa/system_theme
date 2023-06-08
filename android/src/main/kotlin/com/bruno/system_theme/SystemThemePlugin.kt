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
    val accentColor = getDeviceAccentColor(activity)
    val hexColor = java.lang.String.format("#%06X", 0xFFFFFF and accentColor)
    val rgb = getRGB(hexColor)
    result.success(hashMapOf<String, Any?>(
      "accent" to hashMapOf<String, Any?>(
        R" to rgb[0],
        "G" to rgb[1],
        "B" to rgb[2],
        "A" to 1
      )
    ))
  }

  private fun getDeviceAccentColor(context: Context) : Int {
    val value = TypedValue()
    val ctx = ContextThemeWrapper(context, R.style.Theme_DeviceDefault)
    ctx.theme.resolveAttribute(android.R.attr.colorAccent, value, true)
    return value.data
  }

  private fun getRGB(rgb: String): IntArray {
    var color = rgb;
    if (rgb.startsWith("#")) color = rgb.replace("#", "");
    val r = color.substring(0, 2).toInt(16) // 16 for hex
    val g = color.substring(2, 4).toInt(16) // 16 for hex
    val b = color.substring(4, 6).toInt(16) // 16 for hex
    return intArrayOf(r, g, b)
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
