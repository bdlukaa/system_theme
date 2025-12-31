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
          return extractColorFromCss(backgroundColor);
        }
        return null;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'system_theme for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  Map<String, dynamic> extractColorFromCss(String colorString) {
    int r = 255;
    int g = 255;
    int b = 255;
    int a = 255;

    // 1. Handle HEX input (e.g. #FFF, #000000, #000000FF)
    if (colorString.startsWith('#')) {
      var hex = colorString.replaceAll('#', '');

      // Handle 3-digit hex (e.g. #FFF -> #FFFFFF)
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }

      // Handle 6-digit (RRGGBB) or 8-digit (RRGGBBAA)
      if (hex.length == 6 || hex.length == 8) {
        r = int.parse(hex.substring(0, 2), radix: 16);
        g = int.parse(hex.substring(2, 4), radix: 16);
        b = int.parse(hex.substring(4, 6), radix: 16);

        if (hex.length == 8) {
          a = int.parse(hex.substring(6, 8), radix: 16);
        }
      } else {
        throw PlatformException(
          code: 'Unsupported',
          details: 'Invalid Hex color format: $colorString',
        );
      }
    }
    // 2. Handle RGB / RGBA input
    else if (colorString.startsWith('rgb')) {
      final cleanString = colorString
          .replaceAll('rgba', '')
          .replaceAll('rgb', '')
          .replaceAll('(', '')
          .replaceAll(')', '');

      final values = cleanString.split(',').map((s) => s.trim()).toList();

      if (values.length < 3) {
        throw PlatformException(
          code: 'Unsupported',
          details: 'The accent color is not available in this browser.',
        );
      }

      r = int.tryParse(values[0]) ?? 255;
      g = int.tryParse(values[1]) ?? 255;
      b = int.tryParse(values[2]) ?? 255;

      if (values.length > 3) {
        final alphaRaw = values[3];
        // Browser might return alpha as "0.5" (float) or "128" (int)
        // If it contains a dot, treat as float 0.0-1.0 and convert to 0-255
        if (alphaRaw.contains('.')) {
          final alphaFloat = double.tryParse(alphaRaw) ?? 1.0;
          a = (alphaFloat * 255).round();
        } else {
          a = int.tryParse(alphaRaw) ?? 255;
        }
      }
    } else {
      throw PlatformException(
        code: 'Unsupported',
        details: 'Unknown color format: $colorString',
      );
    }

    return {
      'accent': {
        'R': r,
        'G': g,
        'B': b,
        'A': a,
      }
    };
  }
}
