import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:system_theme/system_theme.dart';

/// A web implementation of the SystemTheme plugin.
class SystemThemeWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'system_theme',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = SystemThemeWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case kGetDarkModeMethod:
        return html.window.matchMedia('(prefers-color-scheme: dark)').matches;
      case kGetSystemAccentColorMethod:
        // final e = html.document.getElementById("body");
        // e?.style?.backgroundColor = "highlight";
        // print(e?.style?.backgroundColor);
        return null;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'system_theme for web doesn\'t implement \'${call.method}\'',
        );
    }
  }
}
