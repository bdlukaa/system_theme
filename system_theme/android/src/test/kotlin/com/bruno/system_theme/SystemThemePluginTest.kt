package com.bruno.system_theme

import android.R
import android.content.Context
import android.os.Build
import android.util.TypedValue
import android.view.ContextThemeWrapper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
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
  @Test
  @Config(sdk = [Build.VERSION_CODES.S])
  fun attachRegistersChannelHandlerAndDetachRemovesIt() {
    var handler: Any? = null
    val messenger = Proxy.newProxyInstance(
      BinaryMessenger::class.java.classLoader,
      arrayOf(BinaryMessenger::class.java),
    ) { _, method, arguments ->
      if (method.name == "setMessageHandler" && arguments?.firstOrNull() == "system_theme") {
        handler = arguments[1]
      }
      null
    } as BinaryMessenger
    val context = RuntimeEnvironment.getApplication() as Context
    val binding = FlutterPlugin.FlutterPluginBinding(
      context,
      mock<FlutterEngine>(),
      messenger,
      mock<TextureRegistry>(),
      mock<PlatformViewRegistry>(),
      mock<FlutterPlugin.FlutterAssets>(),
      null,
    )
    val plugin = SystemThemePlugin()

    plugin.onAttachedToEngine(binding)

    assertNotNull(handler)

    plugin.onDetachedFromEngine(binding)

    assertNull(handler)

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
