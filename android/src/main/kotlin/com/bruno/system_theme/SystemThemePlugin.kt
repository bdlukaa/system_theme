package com.bruno.system_theme

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class SystemThemePlugin: FlutterPlugin, ActivityAware, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var activity: Activity

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "system_theme")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "SystemTheme.darkMode") {
      val mode = activity?.resources?.configuration?.uiMode?.and(Configuration.UI_MODE_NIGHT_MASK)
      when (mode) {
        Configuration.UI_MODE_NIGHT_YES -> {
          result.success(true)
        }
        Configuration.UI_MODE_NIGHT_NO -> {
          result.success(false)
        }
        Configuration.UI_MODE_NIGHT_UNDEFINED -> {
          result.success(false)
        }
      }
    else if (call.method == "SystemTheme.accentColor") {
      val accentColor = getDeviceAccentColor(activity)
      result.success(null)
    } else {
      result.notImplemented()
    }
  }

  @ColorInt
  fun getDeviceAccentColor(context: Context) : Int {
    val value = TypedValue()
    val ctx = ContextThemeWrapper(context, android.R.style.Theme_DeviceDefault)
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
