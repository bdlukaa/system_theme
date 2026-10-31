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

void main() {
  final plugin = SystemThemeWeb();
  const call = MethodCall('SystemTheme.accentColor');

  test('reads a browser color and restores the inline background', () async {
    final style = web.document.body!.style;
    final previous = style.getPropertyValue('background-color');
    final priority = style.getPropertyPriority('background-color');
    addTearDown(
      () => style.setProperty('background-color', previous, priority),
    );
    style.setProperty('background-color', 'rgb(1, 2, 3)', 'important');

    final result = await plugin.handleMethodCall(call) as Map;

    expect(result['accent'], isA<Map>());
    final accent = result['accent'] as Map;
    for (final channel in ['R', 'G', 'B', 'A']) {
      expect(accent[channel], inInclusiveRange(0, 255));
    }
    expect(style.getPropertyValue('background-color'), 'rgb(1, 2, 3)');
    expect(style.getPropertyPriority('background-color'), 'important');
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
