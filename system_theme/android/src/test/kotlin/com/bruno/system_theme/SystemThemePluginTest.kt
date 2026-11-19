package com.bruno.system_theme

import android.R
import android.app.Application
import android.content.Context
import android.os.Build
import android.util.TypedValue
import android.view.ContextThemeWrapper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformViewRegistry
import io.flutter.view.TextureRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.mockito.ArgumentCaptor
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import java.lang.reflect.Proxy

@RunWith(RobolectricTestRunner::class)
class SystemThemePluginTest {
  private fun createBinding(
    context: Context,
    messenger: BinaryMessenger = mock(),
  ): FlutterPlugin.FlutterPluginBinding {
    return FlutterPlugin.FlutterPluginBinding(
      context,
      mock<FlutterEngine>(),
      messenger,
      mock<TextureRegistry>(),
      mock<PlatformViewRegistry>(),
      mock<FlutterPlugin.FlutterAssets>(),
      null,
    )
  }

  @Test
  @Config(sdk = [Build.VERSION_CODES.S])
  fun attachRegistersChannelHandlerAndDetachRemovesIt() {
    var methodHandler: Any? = null
    var eventHandler: Any? = null
    val messenger = Proxy.newProxyInstance(
      BinaryMessenger::class.java.classLoader,
      arrayOf(BinaryMessenger::class.java),
    ) { _, method, arguments ->
      if (method.name == "setMessageHandler") {
        when (arguments?.firstOrNull()) {
          "system_theme" -> methodHandler = arguments[1]
          "system_theme_events/switch_callback" -> eventHandler = arguments[1]
        }
      }
      null
    } as BinaryMessenger
    val context = RuntimeEnvironment.getApplication() as Context
    val binding = createBinding(context, messenger)
    val plugin = SystemThemePlugin()

    plugin.onAttachedToEngine(binding)

    assertNotNull(methodHandler)
    assertNotNull(eventHandler)

    plugin.onDetachedFromEngine(binding)

    assertNull(methodHandler)
    assertNull(eventHandler)

    val detachedResult = mock<MethodChannel.Result>()
    plugin.onMethodCall(MethodCall("SystemTheme.accentColor", null), detachedResult)
    verify(detachedResult).success(null)

    plugin.onAttachedToEngine(binding)

    val reattachedResult = mock<MethodChannel.Result>()
    plugin.onMethodCall(MethodCall("SystemTheme.accentColor", null), reattachedResult)
    val color = ArgumentCaptor.forClass(Any::class.java)
    verify(reattachedResult).success(color.capture())
    assertNotNull(color.value)
  }

  @Test
  @Config(sdk = [Build.VERSION_CODES.S])
  fun configurationChangesEmitAccentColorAndStopAfterCancelOrDetach() {
    val application: Application = RuntimeEnvironment.getApplication()
    val binding = createBinding(application)
    val plugin = SystemThemePlugin()
    val emittedEvents = mutableListOf<Any?>()
    val sink = object : EventChannel.EventSink {
      override fun success(event: Any?) {
        emittedEvents.add(event)
      }

      override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {}

      override fun endOfStream() {}
    }

    val color = application.getColor(R.color.system_accent1_500)
    val expected = hashMapOf<String, Any?>(
      "accent" to hashMapOf<String, Any?>(
        "R" to ((color shr 16) and 0xFF),
        "G" to ((color shr 8) and 0xFF),
        "B" to (color and 0xFF),
        "A" to 255,
      ),
    )

    plugin.onAttachedToEngine(binding)
    plugin.onListen(null, sink)
    application.onConfigurationChanged(application.resources.configuration)

    assertEquals(1, emittedEvents.size)
    assertEquals(expected, emittedEvents.single())

    plugin.onCancel(null)
    application.onConfigurationChanged(application.resources.configuration)

    assertEquals(1, emittedEvents.size)

    plugin.onListen(null, sink)
    plugin.onDetachedFromEngine(binding)
    application.onConfigurationChanged(application.resources.configuration)

    assertEquals(1, emittedEvents.size)
  }

  @Test
  fun accentColorCallBeforeEngineAttachmentReturnsNull() {
    val result = mock<MethodChannel.Result>()

    SystemThemePlugin().onMethodCall(MethodCall("SystemTheme.accentColor", null), result)

    verify(result).success(null)
  }

  @Test
  @Suppress("DEPRECATION")
  @Config(sdk = [Build.VERSION_CODES.Q])
  fun pre31UsesLegacyThemeAccent() {
    val context = RuntimeEnvironment.getApplication() as Context
    val themeContext = ContextThemeWrapper(context, R.style.Theme_DeviceDefault)
    val value = TypedValue()
    assertTrue(themeContext.theme.resolveAttribute(R.attr.colorAccent, value, true))
    val expectedColor = when {
      value.type in TypedValue.TYPE_FIRST_COLOR_INT..TypedValue.TYPE_LAST_COLOR_INT -> value.data
      value.resourceId != 0 -> themeContext.resources.getColorStateList(value.resourceId).defaultColor
      else -> null
    }
    val method = SystemThemePlugin::class.java.getDeclaredMethod(
      "getDeviceAccentColor",
      Context::class.java,
    ).apply { isAccessible = true }

    val color = method.invoke(SystemThemePlugin(), context) as Int?

    assertEquals(expectedColor, color)
  }

  @Test
  @Config(sdk = [Build.VERSION_CODES.S])
  fun api31AndAboveUsesDynamicAccentResource() {
    val context = RuntimeEnvironment.getApplication() as Context
    val expectedColor = context.getColor(R.color.system_accent1_500)
    val method = SystemThemePlugin::class.java.getDeclaredMethod(
      "getDeviceAccentColor",
      Context::class.java,
    ).apply { isAccessible = true }

    val color = method.invoke(SystemThemePlugin(), context) as Int

    assertEquals(expectedColor, color)
  }
}
