package com.bruno.system_theme

import android.R
import android.content.ComponentCallbacks
import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import android.os.Build
import android.util.TypedValue
import android.view.ContextThemeWrapper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class SystemThemePlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private var channel: MethodChannel? = null
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null
  private var applicationContext: Context? = null
  private var registeredCallbacksContext: Context? = null

  private val componentCallbacks = object : ComponentCallbacks {
    override fun onConfigurationChanged(newConfig: Configuration) {
      val context = registeredCallbacksContext ?: applicationContext ?: return
      val colors = getAccentColorMap(context) ?: return
      eventSink?.success(colors)
    }

    override fun onLowMemory() {}
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "system_theme")
    channel?.setMethodCallHandler(this)
    eventChannel = EventChannel(
      flutterPluginBinding.binaryMessenger,
      "system_theme_events/switch_callback"
    )
    eventChannel?.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    when (call.method) {
        "SystemTheme.accentColor" -> {
          val context = applicationContext
          result.success(context?.let { getAccentColorMap(it) })
        }
        else -> {
          result.notImplemented()
        }
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    unregisterComponentCallbacks()
    eventSink = events
    val context = applicationContext ?: return
    context.registerComponentCallbacks(componentCallbacks)
    registeredCallbacksContext = context
  }

  override fun onCancel(arguments: Any?) {
    unregisterComponentCallbacks()
    eventSink = null
  }

  private fun unregisterComponentCallbacks() {
    registeredCallbacksContext?.unregisterComponentCallbacks(componentCallbacks)
    registeredCallbacksContext = null
  }

  private fun getAccentColorMap(context: Context): HashMap<String, Any?>? {
    val color = getDeviceAccentColor(context) ?: return null
    val r = (color shr 16) and 0xFF
    val g = (color shr 8) and 0xFF
    val b = color and 0xFF
    // val a = (color shr 24) and 0xFF

    return hashMapOf(
      "accent" to hashMapOf<String, Any?>(
        "R" to r,
        "G" to g,
        "B" to b,
        "A" to 255
      )
    )
  }

  private fun getDeviceAccentColor(context: Context) : Int? {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      try {
        // A stable mid-tone from the system's dynamic primary accent palette.
        // OEMs may provide a fixed palette rather than wallpaper-derived colors.
        return context.getColor(R.color.system_accent1_500)
      } catch (_: Resources.NotFoundException) {
        // Fall back to the legacy theme accent if the dynamic resource is absent.
      }
    }

    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return null

    val value = TypedValue()
    val ctx = ContextThemeWrapper(context, R.style.Theme_DeviceDefault)
    if (!ctx.theme.resolveAttribute(R.attr.colorAccent, value, true)) return null
    if (value.type in TypedValue.TYPE_FIRST_COLOR_INT..TypedValue.TYPE_LAST_COLOR_INT) {
      return value.data
    }
    if (value.resourceId != 0) {
      try {
        @Suppress("DEPRECATION")
        return ctx.resources.getColorStateList(value.resourceId).defaultColor
      } catch (_: Resources.NotFoundException) {
        return null
      }
    }
    return null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    unregisterComponentCallbacks()
    eventSink = null
    eventChannel?.setStreamHandler(null)
    eventChannel = null
    channel?.setMethodCallHandler(null)
    channel = null
    applicationContext = null
  }

}
