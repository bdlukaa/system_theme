import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:system_theme/system_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('system_theme');
  const EventChannel eventChannel = EventChannel(
    'system_theme_events/switch_callback',
  );

  final List<MethodCall> log = <MethodCall>[];

  // Helper to create a color map in the format the plugin expects
  Map<String, dynamic> createColorMap({
    int r = 0,
    int g = 0,
    int b = 0,
    int a = 255,
  }) {
    return {'R': r, 'G': g, 'B': b, 'A': a};
  }

  void resetSingleton() {
    final color = SystemTheme.accentColor;
    color.accent = SystemTheme.kDefaultFallbackColor;
    color.light = SystemTheme.kDefaultFallbackColor;
    color.lighter = SystemTheme.kDefaultFallbackColor;
    color.lightest = SystemTheme.kDefaultFallbackColor;
    color.dark = SystemTheme.kDefaultFallbackColor;
    color.darker = SystemTheme.kDefaultFallbackColor;
    color.darkest = SystemTheme.kDefaultFallbackColor;
  }

  setUp(() {
    log.clear();
    resetSingleton();
    SystemTheme.fallbackColor = SystemTheme.kDefaultFallbackColor;
    SystemTheme.autoAdjustLightness = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'SystemTheme.accentColor') {
            return {'accent': createColorMap(r: 0, g: 0, b: 255)};
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
    for (final platform in [TargetPlatform.windows, TargetPlatform.macOS]) {
      testWidgets('shares change events on $platform', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        late MockStreamHandlerEventSink eventSink;
        var listenCount = 0;
        var cancelCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, sink) {
                  listenCount++;
                  eventSink = sink;
                },
                onCancel: (arguments) {
                  cancelCount++;
                },
              ),
            );

        final receivedByFirst = <SystemAccentColor>[];
        final receivedBySecond = <SystemAccentColor>[];
        final first = SystemTheme.onChange.listen(receivedByFirst.add);
        final second = SystemTheme.onChange.listen(receivedBySecond.add);
        await tester.pump();
        expect(listenCount, 1);

        final color = createColorMap(r: 1, g: 2, b: 3);
        eventSink.success({'accent': color});
        await tester.pump();
        expect(receivedByFirst, hasLength(1));
        expect(receivedBySecond, receivedByFirst);

        await first.cancel();
        expect(cancelCount, 0);
        eventSink.success({'accent': createColorMap(r: 4, g: 5, b: 6)});
        await tester.pump();
        expect(receivedByFirst, hasLength(1));
        expect(receivedBySecond, hasLength(2));

        await second.cancel();
        await tester.pump();
        expect(cancelCount, 1);

        final third = SystemTheme.onChange.listen(receivedByFirst.add);
        await tester.pump();
        expect(listenCount, 2);
        await third.cancel();
        await tester.pump();

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(eventChannel, null);
      });

      testWidgets('multiple builders rebuild on $platform', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        late MockStreamHandlerEventSink eventSink;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, sink) => eventSink = sink,
                onCancel: (arguments) {},
              ),
            );
        var firstBuilds = 0;
        var secondBuilds = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                SystemThemeBuilder(
                  builder: (context, color) {
                    firstBuilds++;
                    return const SizedBox();
                  },
                ),
                SystemThemeBuilder(
                  builder: (context, color) {
                    secondBuilds++;
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        final initialFirstBuilds = firstBuilds;
        final initialSecondBuilds = secondBuilds;
        eventSink.success({'accent': createColorMap(r: 1, g: 2, b: 3)});
        await tester.pump();
        expect(firstBuilds, greaterThan(initialFirstBuilds));
        expect(secondBuilds, greaterThan(initialSecondBuilds));

        await tester.pumpWidget(const SizedBox());
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(eventChannel, null);
      });
    }
    test('Check platform support for accent color', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(defaultTargetPlatform.supportsAccentColor, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      expect(defaultTargetPlatform.supportsAccentColor, isFalse);
    });

    test('Check platform support for listening to changes', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
        defaultTargetPlatform.supportsListeningToAccentColorChanges,
        isTrue,
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        defaultTargetPlatform.supportsListeningToAccentColorChanges,
        isFalse,
      );
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

      final testTheme = SystemAccentColor(SystemTheme.kDefaultFallbackColor);

      await testTheme.load();

      expect(testTheme.accent, SystemTheme.kDefaultFallbackColor);
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
            return {'accent': createColorMap(r: 0, g: 0, b: 255)};
          });

      final testTheme = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
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

      final testTheme = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
      await testTheme.load();

      expect(testTheme.light, platformLightColor);
    });

    test('Disables auto-adjustment when flag is false', () async {
      SystemTheme.autoAdjustLightness = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            return {'accent': createColorMap(r: 0, g: 0, b: 255)};
          });

      final testTheme = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
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
