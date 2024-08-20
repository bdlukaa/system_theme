import 'dart:async';
import 'package:web/web.dart' as web;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

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
      case 'SystemTheme.accentColor':
        final e = web.document.body;
        final currentBackgroundColor = e?.style.backgroundColor;
        e?.style.backgroundColor = 'highlight';
        String? backgroundColor =
            e?.computedStyleMap().get('background-color').toString();

        if (currentBackgroundColor != null) {
          e?.style.backgroundColor = currentBackgroundColor;
        }

        if (backgroundColor != null) {
          backgroundColor = backgroundColor
              // most browsers return rgb, but some may return rgba.
              .replaceAll('rgba', 'rgb')
              .replaceAll('rgb(', '')
              .replaceAll(')', '')
              .replaceAll(' ', '');
          final rgb = backgroundColor.split(',');

          final r = int.tryParse(rgb[0]) ?? 255;
          final g = int.tryParse(rgb[1]) ?? 255;
          final b = int.tryParse(rgb[2]) ?? 255;
          final a = int.tryParse(rgb[3]) ?? 255;

          return {
            'accent': {
              'R': r,
              'G': g,
              'B': b,
              'A': a,
            }
          };
        }
        return null;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'system_theme for web doesn\'t implement \'${call.method}\'',
        );
    }
  }
}
