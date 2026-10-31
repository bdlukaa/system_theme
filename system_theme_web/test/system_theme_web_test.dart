@TestOn('browser')
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:system_theme_web/system_theme_web.dart';
import 'package:web/web.dart' as web;

@JS('window.getComputedStyle')
external JSFunction get _getComputedStyle;

@JS('window.getComputedStyle')
external set _getComputedStyle(JSFunction value);

@JS('CSS.supports')
external JSFunction get _cssSupports;

@JS('CSS.supports')
external set _cssSupports(JSFunction value);

void main() {
  final plugin = SystemThemeWeb();
  const call = MethodCall('SystemTheme.accentColor');

  group('parseCssColor', () {
    final validColors = <String, Map<String, int>>{
      '#abc': {'R': 170, 'G': 187, 'B': 204, 'A': 255},
      '#abcd': {'R': 170, 'G': 187, 'B': 204, 'A': 221},
      '#aabbcc': {'R': 170, 'G': 187, 'B': 204, 'A': 255},
      '#aabbccdd': {'R': 170, 'G': 187, 'B': 204, 'A': 221},
      'rgb(10, 20, 30)': {'R': 10, 'G': 20, 'B': 30, 'A': 255},
      'rgba(10, 20, 30, 0.5)': {'R': 10, 'G': 20, 'B': 30, 'A': 128},
      'rgba(10, 20, 30, 1)': {'R': 10, 'G': 20, 'B': 30, 'A': 255},
      'rgba(10, 20, 30, 0)': {'R': 10, 'G': 20, 'B': 30, 'A': 0},
      'rgb(10 20 30 / 100%)': {'R': 10, 'G': 20, 'B': 30, 'A': 255},
      '#0000': {'R': 0, 'G': 0, 'B': 0, 'A': 0},
      '#FFFFFFFF': {'R': 255, 'G': 255, 'B': 255, 'A': 255},
      'rgb(10 20 30)': {'R': 10, 'G': 20, 'B': 30, 'A': 255},
      'rgb(10 20 30 / 50%)': {'R': 10, 'G': 20, 'B': 30, 'A': 128},
      '  rgb( 10  20  30 / 0 )  ': {'R': 10, 'G': 20, 'B': 30, 'A': 0},
    };

    for (final entry in validColors.entries) {
      test('parses ${entry.key}', () {
        final result = parseCssColor(entry.key)['accent'] as Map;
        expect(result, entry.value);
        for (final channel in result.values) {
          expect(channel, inInclusiveRange(0, 255));
        }
      });
    }

    for (final input in [
      '',
      'not-a-color',
      '#12',
      '#ggg',
      'rgb(10, 20)',
      'rgb(10 20 30 40)',
      'rgb(256 20 30)',
      'rgb(-1 20 30)',
      'rgba(10, 20, 30, 2)',
      'rgb(10 20 30 / 50% / 20%)',
      'rgb(10, nope, 30)',
      'rgb(10, 20, 30 / 50%)',
      'rgb(10 20 30 / invalid)',
      'rgb(10 20 30 / NaN)',
      'rgb(Infinity 20 30)',
      'rgb(10 20 30 / 101%)',
    ]) {
      test('rejects malformed color $input', () {
        expect(() => parseCssColor(input), throwsFormatException);
      });
    }
  });

  test('reads a browser color without changing the body style', () async {
    final body = web.document.body!;
    final originalStyle = body.getAttribute('style');
    addTearDown(() {
      if (originalStyle == null) {
        body.removeAttribute('style');
      } else {
        body.setAttribute('style', originalStyle);
      }
    });
    body.setAttribute(
      'style',
      'background: var(--page-background); accent-color: rgb(4, 5, 6)',
    );
    final expectedStyle = body.getAttribute('style');

    final result = await plugin.handleMethodCall(call);
    if (!web.CSS.supports('background-color', 'AccentColor')) {
      expect(result, isNull);
      return;
    }

    expect(result, isA<Map>());
    expect(result['accent'], isA<Map>());
    final accent = result['accent'] as Map;
    for (final channel in ['R', 'G', 'B', 'A']) {
      expect(accent[channel], inInclusiveRange(0, 255));
    }
    expect(body.getAttribute('style'), expectedStyle);
  });

  test('requests AccentColor using the automatic accent', () async {
    if (!web.CSS.supports('background-color', 'AccentColor')) return;
    final original = _getComputedStyle;
    String? requestedColor;
    String? requestedAccent;
    late Future<dynamic> result;
    try {
      _getComputedStyle = ((JSAny? element) {
        final probe = element! as web.HTMLElement;
        requestedColor = probe.style.getPropertyValue('background-color');
        requestedAccent = probe.style.getPropertyValue('accent-color');
        return {'backgroundColor': 'rgb(8, 16, 32)'}.jsify();
      }).toJS;
      result = plugin.handleMethodCall(call);
    } finally {
      _getComputedStyle = original;
    }

    expect(requestedColor?.toLowerCase(), 'accentcolor');
    expect(requestedAccent,
        web.CSS.supports('accent-color', 'auto') ? 'auto' : '');
    expect(await result, {
      'accent': {'R': 8, 'G': 16, 'B': 32, 'A': 255},
    });
  });

  test(
      'returns null rather than using Highlight when AccentColor is unsupported',
      () async {
    final original = _cssSupports;
    late Future<dynamic> result;
    try {
      _cssSupports = ((JSString property, JSString value) => false.toJS).toJS;
      result = plugin.handleMethodCall(call);
    } finally {
      _cssSupports = original;
    }

    expect(await result, isNull);
  });

  for (final color in ['', 'rgba(10, 20, 30, invalid)']) {
    test('returns null for an unavailable or malformed computed color: $color',
        () async {
      final original = _getComputedStyle;
      late Future<dynamic> result;
      try {
        _getComputedStyle =
            ((JSAny? element) => {'backgroundColor': color}.jsify()).toJS;
        result = plugin.handleMethodCall(call);
      } finally {
        _getComputedStyle = original;
      }

      expect(await result, isNull);
    });
  }

  test('reads a controlled color through the browser computed-style API',
      () async {
    final body = web.document.body!;
    final bodyStyle = body.getAttribute('style');
    final childCount = body.children.length;
    final originalComputedStyle = _getComputedStyle;
    final originalSupports = _cssSupports;
    web.HTMLElement? probe;
    try {
      _cssSupports = ((JSString property, JSString value) => true.toJS).toJS;
      _getComputedStyle = ((JSAny? element) {
        probe = element! as web.HTMLElement;
        expect(probe!.isConnected, isTrue);
        probe!.style.setProperty('background-color', 'rgba(8, 16, 32, 0.5)');
        return originalComputedStyle.callAsFunction(web.window, element);
      }).toJS;

      expect(await plugin.handleMethodCall(call), {
        'accent': {'R': 8, 'G': 16, 'B': 32, 'A': 128},
      });
      expect(probe, isNotNull);
      expect(probe!.isConnected, isFalse);
      expect(body.children.length, childCount);
      expect(body.getAttribute('style'), bodyStyle);
    } finally {
      _getComputedStyle = originalComputedStyle;
      _cssSupports = originalSupports;
    }
  });

  test('cleans up the probe when computed styles throw', () async {
    final body = web.document.body!;
    final bodyStyle = body.getAttribute('style');
    final childCount = body.children.length;
    final originalComputedStyle = _getComputedStyle;
    final originalSupports = _cssSupports;
    web.HTMLElement? probe;
    try {
      _cssSupports = ((JSString property, JSString value) => true.toJS).toJS;
      JSAny? failComputedStyle(JSAny? element) {
        probe = element! as web.HTMLElement;
        throw StateError('computed style unavailable');
      }

      _getComputedStyle = failComputedStyle.toJS;
      expect(await plugin.handleMethodCall(call), isNull);
      expect(probe, isNotNull);
      expect(probe!.isConnected, isFalse);
      expect(body.children.length, childCount);
      expect(body.getAttribute('style'), bodyStyle);
    } finally {
      _getComputedStyle = originalComputedStyle;
      _cssSupports = originalSupports;
    }
  });

  test('returns null when CSS feature detection throws', () async {
    final originalSupports = _cssSupports;
    try {
      JSBoolean failSupports(JSString property, JSString value) {
        throw StateError('CSS.supports unavailable');
      }

      _cssSupports = failSupports.toJS;
      expect(await plugin.handleMethodCall(call), isNull);
    } finally {
      _cssSupports = originalSupports;
    }
  });

  test('registers the method channel and returns encoded responses', () async {
    final registrar = Registrar();
    SystemThemeWeb.registerWith(registrar);
    const codec = StandardMethodCodec();
    final originalComputedStyle = _getComputedStyle;
    final originalSupports = _cssSupports;
    try {
      _cssSupports = ((JSString property, JSString value) => true.toJS).toJS;
      _getComputedStyle = ((JSAny? element) =>
          {'backgroundColor': 'rgb(8, 16, 32)'}.jsify()).toJS;
      Object? response;
      await registrar.handleFrameworkMessage(
        'system_theme',
        codec.encodeMethodCall(call),
        (data) => response = codec.decodeEnvelope(data!),
      );
      expect(response, {
        'accent': {'R': 8, 'G': 16, 'B': 32, 'A': 255},
      });

      _getComputedStyle =
          ((JSAny? element) => {'backgroundColor': 'unsupported'}.jsify()).toJS;
      await registrar.handleFrameworkMessage(
        'system_theme',
        codec.encodeMethodCall(call),
        (data) => response = codec.decodeEnvelope(data!),
      );
      expect(response, isNull);

      await expectLater(
        registrar.handleFrameworkMessage(
          'system_theme',
          codec.encodeMethodCall(const MethodCall('unsupportedMethod')),
          (data) => codec.decodeEnvelope(data!),
        ),
        throwsA(isA<PlatformException>()
            .having((error) => error.code, 'code', 'Unimplemented')),
      );
    } finally {
      _getComputedStyle = originalComputedStyle;
      _cssSupports = originalSupports;
    }
  });

  test('returns null when the document has no body', () async {
    final body = web.document.body!;
    final parent = body.parentNode!;
    final nextSibling = body.nextSibling;
    body.remove();
    try {
      expect(await plugin.handleMethodCall(call), isNull);
    } finally {
      parent.insertBefore(body, nextSibling);
    }
  });
}
