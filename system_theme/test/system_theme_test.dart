import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_theme/system_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('system_theme');

  final List<MethodCall> log = <MethodCall>[];

  // Helper to create a color map in the format the plugin expects
  Map<String, dynamic> createColorMap(
      {int r = 0, int g = 0, int b = 0, int a = 255}) {
    return {'R': r, 'G': g, 'B': b, 'A': a};
  }

  void resetSingleton() {
    final color = SystemTheme.accentColor;
    color.accent = kDefaultFallbackColor;
    color.light = kDefaultFallbackColor;
    color.lighter = kDefaultFallbackColor;
    color.lightest = kDefaultFallbackColor;
    color.dark = kDefaultFallbackColor;
    color.darker = kDefaultFallbackColor;
    color.darkest = kDefaultFallbackColor;
  }

  setUp(() {
    log.clear();
    resetSingleton();
    SystemTheme.fallbackColor = kDefaultFallbackColor;
    SystemTheme.autoAdjustLightness = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == 'SystemTheme.accentColor') {
        return {
          'accent': createColorMap(r: 0, g: 0, b: 255),
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('SystemTheme', () {
    test('Check platform support for accent color', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(defaultTargetPlatform.supportsAccentColor, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      expect(defaultTargetPlatform.supportsAccentColor, isFalse);
    });

    test('Check platform support for listening to changes', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
          defaultTargetPlatform.supportsListeningToAccentColorChanges, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
          defaultTargetPlatform.supportsListeningToAccentColorChanges, isFalse);
    });

    test('Loads accent color correctly (Singleton)', () async {
      await SystemTheme.accentColor.load();

      expect(log, isNotEmpty);
      expect(log.last.method, 'SystemTheme.accentColor');

      expect(SystemTheme.accentColor.accent, const Color(0xFF0000FF));
    });

    test('Handles MissingPluginException gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw MissingPluginException();
      });

      final testTheme = SystemAccentColor(kDefaultFallbackColor);

      await testTheme.load();

      expect(testTheme.accent, kDefaultFallbackColor);
    });

    test('Respects custom fallback color', () async {
      const customFallback = Color(0xFF123456);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });

      final testTheme = SystemAccentColor(customFallback);

      await testTheme.load();

      expect(testTheme.accent, customFallback);
    });
  });

  group('SystemAccentColor Variant Logic', () {
    test('Auto-generates variants when platform only returns accent', () async {
      SystemTheme.autoAdjustLightness = true;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return {
          'accent': createColorMap(r: 0, g: 0, b: 255),
        };
      });

      final testTheme = SystemAccentColor(kDefaultFallbackColor);
      await testTheme.load();

      expect(testTheme.accent, const Color(0xFF0000FF));
      expect(testTheme.light, isNot(testTheme.accent));
      expect(testTheme.dark, isNot(testTheme.accent));
    });

    test('Uses platform variants when provided', () async {
      SystemTheme.autoAdjustLightness = true;

      const platformLightColor = Color(0xFF00FF00);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return {
          'accent': createColorMap(r: 0, g: 0, b: 255),
          'light': createColorMap(r: 0, g: 255, b: 0),
        };
      });

      final testTheme = SystemAccentColor(kDefaultFallbackColor);
      await testTheme.load();

      expect(testTheme.light, platformLightColor);
    });

    test('Disables auto-adjustment when flag is false', () async {
      SystemTheme.autoAdjustLightness = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return {
          'accent': createColorMap(r: 0, g: 0, b: 255),
        };
      });

      final testTheme = SystemAccentColor(kDefaultFallbackColor);
      await testTheme.load();

      expect(testTheme.light, testTheme.accent);
    });
  });

  group('Object contracts', () {
    test('Equality and Hashcode', () async {
      final color1 = SystemTheme.accentColor;
      final color2 = SystemTheme.accentColor;

      expect(color1, equals(color2));
      expect(color1.hashCode, equals(color2.hashCode));
    });

    test('toString contains class name', () {
      expect(SystemTheme.accentColor.toString(), contains('SystemAccentColor'));
    });
  });
}
