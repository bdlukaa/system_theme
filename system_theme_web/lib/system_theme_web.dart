import 'dart:async';

import 'package:web/web.dart' as web;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A web implementation of the SystemTheme plugin.
///
/// Uses the browser's CSS `AccentColor`, which may be a browser default rather
/// than the OS accent color. When unavailable, the plugin returns no color so
/// the calling package can retain its configured fallback or last palette.
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
        final body = web.document.body;
        if (body == null) return null;

        try {
          if (!web.CSS.supports('background-color', 'AccentColor')) return null;

          final probe = web.document.createElement('div') as web.HTMLElement;
          probe.style.setProperty('display', 'none');
          probe.style.setProperty('accent-color', 'auto');
          probe.style.setProperty('background-color', 'AccentColor');
          body.append(probe);
          try {
            final backgroundColor =
                web.window.getComputedStyle(probe).backgroundColor;
            if (backgroundColor.isEmpty) return null;
            return extractColorFromCss(backgroundColor);
          } finally {
            probe.remove();
          }
        } catch (_) {
          return null;
        }
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'system_theme for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  Map<String, dynamic> extractColorFromCss(String colorString) =>
      parseCssColor(colorString);
}

/// Parses supported CSS RGB and hexadecimal colors into 8-bit channels.
///
/// Throws [FormatException] for unsupported or malformed color strings.
Map<String, dynamic> parseCssColor(String colorString) {
  final input = colorString.trim();
  if (input.startsWith('#')) {
    final hex = input.substring(1);
    if (!RegExp(r'^(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$')
        .hasMatch(hex)) {
      throw FormatException('Invalid hexadecimal color', colorString);
    }

    final digits = hex.length <= 4
        ? hex.split('').map((digit) => '$digit$digit').join()
        : hex;
    final channels = [
      for (var index = 0; index < digits.length; index += 2)
        int.parse(digits.substring(index, index + 2), radix: 16),
    ];
    if (channels.length == 3) channels.add(255);
    return _colorMap(channels);
  }

  final function =
      RegExp(r'^rgba?\((.*)\)$', caseSensitive: false).firstMatch(input);
  if (function == null) {
    throw FormatException('Unsupported CSS color', colorString);
  }

  final body = function.group(1)!.trim();
  final slashParts = body.split('/');
  if (slashParts.length > 2 || (body.contains(',') && slashParts.length == 2)) {
    throw FormatException('Invalid CSS RGB color', colorString);
  }

  final componentText = slashParts.first.trim();
  final hasCommaSyntax = componentText.contains(',');
  final components = hasCommaSyntax
      ? componentText.split(',').map((part) => part.trim()).toList()
      : componentText.split(RegExp(r'\s+'));
  String? alphaText = slashParts.length == 2 ? slashParts[1].trim() : null;
  if (hasCommaSyntax && components.length == 4) {
    if (alphaText != null) {
      throw FormatException('Invalid CSS RGB color', colorString);
    }
    alphaText = components.removeLast();
  }
  if (components.length != 3 || (alphaText?.isEmpty ?? false)) {
    throw FormatException('Invalid CSS RGB color', colorString);
  }

  final channels = components.map((component) {
    final value = double.tryParse(component);
    if (value == null || !value.isFinite || value < 0 || value > 255) {
      throw FormatException('Invalid RGB channel', colorString);
    }
    return value.round();
  }).toList();

  var alpha = 255;
  if (alphaText != null) {
    final isPercentage = alphaText.endsWith('%');
    final value = double.tryParse(
      isPercentage ? alphaText.substring(0, alphaText.length - 1) : alphaText,
    );
    final maximum = isPercentage ? 100 : 1;
    if (value == null || !value.isFinite || value < 0 || value > maximum) {
      throw FormatException('Invalid CSS alpha channel', colorString);
    }
    alpha = ((isPercentage ? value / 100 : value) * 255).round();
  }
  channels.add(alpha);
  return _colorMap(channels);
}

Map<String, dynamic> _colorMap(List<int> channels) => {
      'accent': {
        'R': channels[0],
        'G': channels[1],
        'B': channels[2],
        'A': channels[3],
      },
    };
