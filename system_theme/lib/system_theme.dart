import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart'
    show Color, EventChannel, MethodChannel, MissingPluginException;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;

export 'system_theme_builder.dart';

/// Default system accent color.
const kDefaultFallbackColor = Color(0xff00b7c3);

const kGetSystemAccentColorMethod = 'SystemTheme.accentColor';

/// Platform event channel handler for system theme changes.
const _eventChannel = EventChannel('system_theme_events/switch_callback');

/// Platform channel handler for invoking native methods.
const MethodChannel _channel = MethodChannel('system_theme');

extension PlatformHelpers on TargetPlatform {
  /// A helper that can be used to check if the current platform supports
  /// accent colors.
  bool get supportsAccentColor =>
      kIsWeb ||
      [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.iOS,
        TargetPlatform.android,
        TargetPlatform.linux,
      ].contains(this);

  /// Whether this platform supports listening to accent color changes.
  bool get supportsListeningToAccentColorChanges =>
      !kIsWeb && [TargetPlatform.windows, TargetPlatform.macOS].contains(this);
}

/// Class to return current system theme state on Windows.
///
/// [accentColor] returns the current accent color as a [SystemAccentColor].
///
/// To configure a fallback color if [accentColor] is not available, set
/// [fallbackColor] to the desired color
///
/// [onChange] returns a stream of [SystemAccentColor] that notifies when the
/// system accent color changes.
class SystemTheme {
  /// The fallback color
  ///
  /// Returns [kDefaultFallbackColor] if not set
  static Color fallbackColor = kDefaultFallbackColor;

  /// Whether to automatically adjust lightness if the color if the platform
  /// doesn't support it natively.
  ///
  /// Enabled by default.
  static bool autoAdjustLightness = true;

  /// Get the system accent color.
  ///
  /// This is available for the following platforms:
  ///   - Windows
  ///   - Web
  ///   - Android
  ///   - iOS
  ///   - Mac
  ///   - Linux
  ///
  /// It returns [kDefaultFallbackColor] for unsupported platforms
  static final SystemAccentColor accentColor = SystemAccentColor(fallbackColor)
    ..load();

  /// A stream of [SystemAccentColor] that notifies when the system accent color
  /// changes.
  ///
  /// Currently only available on Windows.
  ///
  /// Basica usage:
  ///
  /// ```dart
  /// SystemTheme.onChange.listen((color) {
  ///   debugPrint('Accent color changed to ${color.accent}');
  /// });
  /// ```
  static Stream<SystemAccentColor> get onChange {
    if (!defaultTargetPlatform.supportsListeningToAccentColorChanges) {
      return Stream.value(accentColor);
    }

    return _eventChannel.receiveBroadcastStream().map((event) {
      return SystemAccentColor._fromMap(event);
    }).distinct();
  }
}

/// Defines accent colors & its variants.
/// Colors are cached by default, call [SystemAccentColor.load] to update the
/// colors.
///
/// It returns [SystemAccentColor.defaultAccentColor] if
/// [SystemAccentColor.load] fails
class SystemAccentColor {
  StreamSubscription<SystemAccentColor>? _subscription;

  /// The accent color used when the others are not available.
  final Color defaultAccentColor;

  /// Base accent color.
  late Color accent;

  /// Light shade.
  late Color light;

  /// Lighter shade.
  late Color lighter;

  /// Lighest shade.
  late Color lightest;

  /// Darkest shade.
  late Color dark;

  /// Darker shade.
  late Color darker;

  /// Darkest shade.
  late Color darkest;

  SystemAccentColor(this.defaultAccentColor) {
    accent = defaultAccentColor;
    light = defaultAccentColor;
    lighter = defaultAccentColor;
    lightest = defaultAccentColor;
    dark = defaultAccentColor;
    darker = defaultAccentColor;
    darkest = defaultAccentColor;
  }

  SystemAccentColor._fromMap(dynamic colors)
      : defaultAccentColor = SystemTheme.fallbackColor {
    _retrieveFromColors(colors);
  }

  /// Updates the fetched accent colors on Windows.
  Future<void> load() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final colors = await _channel.invokeMethod(kGetSystemAccentColorMethod);
      if (colors == null) return;
      _retrieveFromColors(colors);
    } on MissingPluginException {
      debugPrint('system_theme does not implement the current platform');
      return;
    } catch (_) {
      rethrow;
    }

    _subscription ??= SystemTheme.onChange.listen((color) {
      accent = color.accent;
      light = color.light;
      lighter = color.lighter;
      lightest = color.lightest;
      dark = color.dark;
      darker = color.darker;
      darkest = color.darkest;
    });
  }

  void _retrieveFromColors(dynamic colors) {
    accent = _retrieve(colors['accent']) ?? defaultAccentColor;

    light = _retrieve(colors['light']) ?? _adjustLightness(accent, 0.1);
    lighter = _retrieve(colors['lighter']) ?? _adjustLightness(accent, 0.2);
    lightest = _retrieve(colors['lightest']) ?? _adjustLightness(accent, 0.3);

    dark = _retrieve(colors['dark']) ?? _adjustLightness(accent, -0.1);
    darker = _retrieve(colors['darker']) ?? _adjustLightness(accent, -0.2);
    darkest = _retrieve(colors['darkest']) ?? _adjustLightness(accent, -0.3);
  }

  Color _adjustLightness(Color color, double amount) {
    if (!SystemTheme.autoAdjustLightness) return color;
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  Color? _retrieve(dynamic map) {
    assert(map == null || map is Map);
    if (map == null) return null;
    return Color.fromARGB(map['A'] ?? 255, map['R'], map['G'], map['B']);
  }

  /// Releases any used resources
  void dispose() {
    _subscription?.cancel();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SystemAccentColor &&
        other.defaultAccentColor == defaultAccentColor &&
        other.accent == accent &&
        other.light == light &&
        other.lighter == lighter &&
        other.lightest == lightest &&
        other.dark == dark &&
        other.darker == darker &&
        other.darkest == darkest;
  }

  @override
  int get hashCode {
    return defaultAccentColor.hashCode ^
        accent.hashCode ^
        light.hashCode ^
        lighter.hashCode ^
        lightest.hashCode ^
        dark.hashCode ^
        darker.hashCode ^
        darkest.hashCode;
  }

  @override
  String toString() {
    return 'SystemAccentColor(defaultAccentColor: $defaultAccentColor, accent: $accent, light: $light, lighter: $lighter, lightest: $lightest, dark: $dark, darker: $darker, darkest: $darkest)';
  }
}
