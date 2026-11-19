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
    color.dispose();
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
    test(
      'Changing fallback updates singleton shades before native colors load',
      () {
        const fallback = Color(0xFF123456);
        SystemTheme.fallbackColor = fallback;

        final color = SystemTheme.accentColor;
        expect(color.defaultAccentColor, fallback);
        expect([
          color.accent,
          color.light,
          color.lighter,
          color.lightest,
          color.dark,
          color.darker,
          color.darkest,
        ], everyElement(fallback));

        SystemTheme.fallbackColor = SystemTheme.kDefaultFallbackColor;
      },
    );

    test('Fallback changes preserve loaded native colors', () async {
      final color = SystemTheme.accentColor;
      await color.load();
      final nativeAccent = color.accent;
      const newFallback = Color(0xFF123456);

      SystemTheme.fallbackColor = newFallback;

      expect(color.accent, nativeAccent);
      expect(color.defaultAccentColor, newFallback);
      SystemTheme.fallbackColor = SystemTheme.kDefaultFallbackColor;
    });

    test('Reading accentColor does not perform platform I/O', () {
      expect(SystemTheme.accentColor.accent, SystemTheme.fallbackColor);
      expect(log, isEmpty);
    });

    test('Concurrent initialization shares one operation', () async {
      final color = SystemTheme.accentColor;
      await Future.wait([color.load(), color.load()]);

      expect(log, hasLength(1));
      expect(color.accent, const Color(0xFF0000FF));
    });

    test('Initial null response keeps the fallback palette', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async => null);
      final color = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
      addTearDown(color.dispose);

      await color.load();

      expect([
        color.accent,
        color.light,
        color.lighter,
        color.lightest,
        color.dark,
        color.darker,
        color.darkest,
      ], everyElement(SystemTheme.kDefaultFallbackColor));
    });

    test('Failed refresh preserves the last successful palette', () async {
      var attempts = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            attempts++;
            if (attempts == 1) {
              return {'accent': createColorMap(r: 10, g: 20, b: 30)};
            }
            throw PlatformException(code: 'refresh-failed');
          });
      final color = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
      addTearDown(color.dispose);
      await color.load();
      final palette = [
        color.accent,
        color.light,
        color.lighter,
        color.lightest,
        color.dark,
        color.darker,
        color.darkest,
      ];

      await expectLater(color.load(), throwsA(isA<PlatformException>()));

      expect([
        color.accent,
        color.light,
        color.lighter,
        color.lightest,
        color.dark,
        color.darker,
        color.darkest,
      ], palette);
    });

    test(
      'Malformed or incomplete responses preserve the current palette',
      () async {
        final color = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
        addTearDown(color.dispose);
        final previousAccent = color.accent;
        final previousLight = color.light;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (methodCall) async {
              return {
                'accent': {'R': 12, 'G': 34},
              };
            });

        await expectLater(color.load(), throwsA(isA<FormatException>()));

        expect(color.accent, previousAccent);
        expect(color.light, previousLight);
      },
    );

    test('Successful refresh replaces the complete palette', () async {
      var attempts = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            attempts++;
            final value = attempts == 1 ? 10 : 20;
            return {
              'accent': createColorMap(r: value, g: value, b: value),
              'light': createColorMap(r: value + 1, g: value + 1, b: value + 1),
              'lighter': createColorMap(
                r: value + 2,
                g: value + 2,
                b: value + 2,
              ),
              'lightest': createColorMap(
                r: value + 3,
                g: value + 3,
                b: value + 3,
              ),
              'dark': createColorMap(r: value + 4, g: value + 4, b: value + 4),
              'darker': createColorMap(
                r: value + 5,
                g: value + 5,
                b: value + 5,
              ),
              'darkest': createColorMap(
                r: value + 6,
                g: value + 6,
                b: value + 6,
              ),
            };
          });
      final color = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
      addTearDown(color.dispose);

      await color.load();
      await color.load();

      expect(
        [
          color.accent,
          color.light,
          color.lighter,
          color.lightest,
          color.dark,
          color.darker,
          color.darkest,
        ],
        [
          const Color(0xFF141414),
          const Color(0xFF151515),
          const Color(0xFF161616),
          const Color(0xFF171717),
          const Color(0xFF181818),
          const Color(0xFF191919),
          const Color(0xFF1A1A1A),
        ],
      );
    });

    test('A later load performs a fresh platform request', () async {
      final color = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
      addTearDown(color.dispose);
      await color.load();
      await color.load();

      expect(log, hasLength(2));
    });

    test('A failed load can be retried', () async {
      var attempts = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            attempts++;
            if (attempts == 1) throw PlatformException(code: 'failure');
            return {'accent': createColorMap(r: 9, g: 8, b: 7)};
          });
      final color = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
      addTearDown(color.dispose);

      final firstLoad = color.load();
      final secondLoad = color.load();
      expect(identical(firstLoad, secondLoad), isTrue);
      await expectLater(
        Future.wait([firstLoad, secondLoad]),
        throwsA(isA<PlatformException>()),
      );
      await color.load();

      expect(attempts, 2);
      expect(color.accent, const Color(0xFF090807));
    });

    test('Failed palette parsing does not partially update colors', () async {
      final color = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
      addTearDown(color.dispose);
      final previousAccent = color.accent;
      final previousLight = color.light;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            return {
              'accent': createColorMap(r: 9, g: 8, b: 7),
              'light': {'R': 1},
            };
          });

      await expectLater(color.load(), throwsA(isA<FormatException>()));

      expect(color.accent, previousAccent);
      expect(color.light, previousLight);
    });

    test('Explicit platform failures are propagated', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            throw PlatformException(code: 'failure');
          });

      await expectLater(
        SystemTheme.accentColor.load(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('Unsupported platforms retain the fallback color', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            throw MissingPluginException();
          });
      final color = SystemAccentColor(SystemTheme.kDefaultFallbackColor);
      addTearDown(color.dispose);

      await color.load();

      expect(color.accent, SystemTheme.kDefaultFallbackColor);
    });

    testWidgets(
      'explicit reload updates both builders without duplicate updates',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (methodCall) async {
              return {'accent': createColorMap(r: 12, g: 34, b: 56)};
            });
        final firstValues = <Color>[];
        final secondValues = <Color>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                SystemThemeBuilder(
                  builder: (context, color) {
                    firstValues.add(color.accent);
                    return const SizedBox();
                  },
                ),
                SystemThemeBuilder(
                  builder: (context, color) {
                    secondValues.add(color.accent);
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        final initialFirstBuilds = firstValues.length;
        final initialSecondBuilds = secondValues.length;

        await SystemTheme.accentColor.load();
        await tester.pumpAndSettle();
        expect(firstValues.last, const Color(0xFF0C2238));
        expect(secondValues.last, const Color(0xFF0C2238));
        final updatedFirstBuilds = firstValues.length;
        final updatedSecondBuilds = secondValues.length;
        expect(updatedFirstBuilds, greaterThan(initialFirstBuilds));
        expect(updatedSecondBuilds, greaterThan(initialSecondBuilds));

        await SystemTheme.accentColor.load();
        await tester.pumpAndSettle();
        expect(firstValues, hasLength(updatedFirstBuilds));
        expect(secondValues, hasLength(updatedSecondBuilds));

        await tester.pumpWidget(const SizedBox());
        debugDefaultTargetPlatformOverride = null;
      },
    );

    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.android,
      TargetPlatform.linux,
    ]) {
      testWidgets('native events and reloads are deduplicated on $platform', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = platform;
        late MockStreamHandlerEventSink eventSink;
        var cancelCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, sink) {
                  eventSink = sink;
                },
                onCancel: (arguments) {
                  cancelCount++;
                },
              ),
            );
        final events = <SystemAccentColor>[];
        final subscription = SystemTheme.onChange.listen(events.add);
        await tester.pump();

        eventSink.success({'accent': createColorMap(b: 255)});
        await tester.pump();
        expect(events, hasLength(1));

        await SystemTheme.accentColor.load();
        await tester.pump();
        expect(events, hasLength(1));

        subscription.cancel();
        SystemTheme.accentColor.dispose();
        await tester.pump();
        expect(cancelCount, 1);
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(eventChannel, null);
      });

      testWidgets('reloads a disposed color on $platform', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
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
        final color = SystemAccentColor(SystemTheme.kDefaultFallbackColor);

        await color.load();
        await tester.pump();
        expect(listenCount, 1);
        eventSink.success({'accent': createColorMap(r: 1, g: 2, b: 3)});
        await tester.pump();
        final beforeDispose = color.accent;

        color.dispose();
        color.dispose();
        eventSink.success({'accent': createColorMap(r: 4, g: 5, b: 6)});
        await tester.pump();
        expect(color.accent, beforeDispose);
        expect(cancelCount, 1);

        await color.load();
        await tester.pump();
        expect(listenCount, 2);
        eventSink.success({'accent': createColorMap(r: 7, g: 8, b: 9)});
        await tester.pump();
        expect(color.accent, const Color(0xFF070809));

        color.dispose();
        await tester.pump();
        expect(cancelCount, 2);
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(eventChannel, null);
      });

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

        first.cancel();
        await tester.pump();
        expect(cancelCount, 0);
        eventSink.success({'accent': createColorMap(r: 4, g: 5, b: 6)});
        await tester.pump();
        expect(receivedByFirst, hasLength(1));
        expect(receivedBySecond, hasLength(2));
        expect(receivedBySecond.last.accent, const Color(0xFF040506));
        eventSink.success({'accent': createColorMap(r: 4, g: 5, b: 6)});
        await tester.pump();
        expect(receivedBySecond, hasLength(2));

        second.cancel();
        await tester.pump();
        expect(cancelCount, 1);

        final third = SystemTheme.onChange.listen(receivedByFirst.add);
        await tester.pump();
        expect(listenCount, 2);
        eventSink.success({'accent': createColorMap(r: 7, g: 8, b: 9)});
        await tester.pump();
        expect(receivedByFirst, hasLength(2));
        expect(receivedByFirst.last.accent, const Color(0xFF070809));
        third.cancel();
        await tester.pump();
        expect(cancelCount, 2);
        debugDefaultTargetPlatformOverride = null;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(eventChannel, null);
      });

      testWidgets('multiple builders rebuild on $platform', (tester) async {
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
                onCancel: (arguments) => cancelCount++,
              ),
            );
        final firstColors = <Color>[];
        final secondColors = <Color>[];

        Widget builders({required bool showFirst}) => Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              if (showFirst)
                SystemThemeBuilder(
                  key: const ValueKey('first'),
                  builder: (context, color) {
                    firstColors.add(color.accent);
                    return const SizedBox();
                  },
                ),
              SystemThemeBuilder(
                key: const ValueKey('second'),
                builder: (context, color) {
                  secondColors.add(color.accent);
                  return const SizedBox();
                },
              ),
            ],
          ),
        );

        await tester.pumpWidget(builders(showFirst: true));
        await tester.pump();
        expect(listenCount, 1);
        final initialFirstBuilds = firstColors.length;
        final initialSecondBuilds = secondColors.length;
        eventSink.success({'accent': createColorMap(r: 1, g: 2, b: 3)});
        await tester.pump();
        await tester.pump();
        expect(firstColors.length, greaterThan(initialFirstBuilds));
        expect(secondColors.length, greaterThan(initialSecondBuilds));
        expect(firstColors.last, const Color(0xFF010203));
        expect(secondColors.last, const Color(0xFF010203));

        await tester.pumpWidget(builders(showFirst: false));
        expect(cancelCount, 0);
        final firstBuildsAfterRemoval = firstColors.length;
        eventSink.success({'accent': createColorMap(r: 4, g: 5, b: 6)});
        await tester.pump();
        await tester.pump();
        expect(firstColors, hasLength(firstBuildsAfterRemoval));
        expect(secondColors.last, const Color(0xFF040506));

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(cancelCount, 1);
        debugDefaultTargetPlatformOverride = null;
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
      for (final platform in [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.android,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          defaultTargetPlatform.supportsListeningToAccentColorChanges,
          isTrue,
        );
      }

      for (final platform in [TargetPlatform.iOS, TargetPlatform.fuchsia]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          defaultTargetPlatform.supportsListeningToAccentColorChanges,
          isFalse,
        );
      }
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
      addTearDown(testTheme.dispose);

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
      addTearDown(testTheme.dispose);

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
      addTearDown(testTheme.dispose);
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
      addTearDown(testTheme.dispose);
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
      addTearDown(testTheme.dispose);
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
