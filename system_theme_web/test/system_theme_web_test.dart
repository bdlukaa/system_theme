@TestOn('browser')
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('reads a browser color and restores the inline background', () async {
    final style = web.document.body!.style;
    final previous = style.getPropertyValue('background-color');
    final priority = style.getPropertyPriority('background-color');
    final previousAccent = style.getPropertyValue('accent-color');
    final accentPriority = style.getPropertyPriority('accent-color');
    addTearDown(() {
      style.setProperty('background-color', previous, priority);
      style.setProperty('accent-color', previousAccent, accentPriority);
    });
    style.setProperty('background-color', 'rgb(1, 2, 3)', 'important');
    style.setProperty('accent-color', 'rgb(4, 5, 6)', 'important');

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
    expect(style.getPropertyValue('background-color'), 'rgb(1, 2, 3)');
    expect(style.getPropertyPriority('background-color'), 'important');
    if (web.CSS.supports('accent-color', 'auto')) {
      expect(style.getPropertyValue('accent-color'), 'rgb(4, 5, 6)');
      expect(style.getPropertyPriority('accent-color'), 'important');
    }
  });

  test('requests AccentColor using the automatic accent', () async {
    if (!web.CSS.supports('background-color', 'AccentColor')) return;
    final original = _getComputedStyle;
    String? requestedColor;
    String? requestedAccent;
    late Future<dynamic> result;
    try {
      _getComputedStyle = ((JSAny? element) {
        final style = web.document.body!.style;
        requestedColor = style.getPropertyValue('background-color');
        requestedAccent = style.getPropertyValue('accent-color');
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

  test('returns null for an unavailable computed color', () async {
    final original = _getComputedStyle;
    late Future<dynamic> result;
    try {
      _getComputedStyle =
          ((JSAny? element) => {'backgroundColor': ''}.jsify()).toJS;
      result = plugin.handleMethodCall(call);
    } finally {
      _getComputedStyle = original;
    }

    expect(await result, isNull);
  });

  test('returns null when the document has no body', () async {
    final body = web.document.body!;
    final parent = body.parentNode!;
    final nextSibling = body.nextSibling;
    body.remove();
    final result = plugin.handleMethodCall(call);
    parent.insertBefore(body, nextSibling);

    expect(await result, isNull);
  });
}
