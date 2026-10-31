package com.bruno.system_theme

import android.R
import android.content.Context
import android.content.res.Resources
import android.os.Build
import android.util.TypedValue
import android.view.ContextThemeWrapper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class SystemThemePlugin: FlutterPlugin, MethodCallHandler {
  private var channel: MethodChannel? = null
  private var applicationContext: Context? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "system_theme")
    channel?.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    when (call.method) {
        "SystemTheme.accentColor" -> {
          val context = applicationContext
          val color = context?.let { getDeviceAccentColor(it) }
          if (color == null) {
            result.success(null)
            return
          }
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
    channel?.setMethodCallHandler(null)
    channel = null
    applicationContext = null
  }

}
