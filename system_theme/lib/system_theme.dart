import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, kIsWeb;
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

  /// Get the system accent color.
  ///
  /// This is available for the following platforms:
  ///   - Windows
  ///   - Web
  ///   - Android
  ///   - iOS
  ///   - Mac
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
    if (kIsWeb || !Platform.isWindows) return Stream.value(accentColor);

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
    accent = _retrieve(colors['accent']) ?? defaultAccentColor;
    light = _retrieve(colors['light']) ?? accent;
    lighter = _retrieve(colors['lighter']) ?? accent;
    lightest = _retrieve(colors['lightest']) ?? accent;
    dark = _retrieve(colors['dark']) ?? accent;
    darker = _retrieve(colors['darker']) ?? accent;
    darkest = _retrieve(colors['darkest']) ?? accent;
  }

  /// Updates the fetched accent colors on Windows.
  Future<void> load() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final colors = await _channel.invokeMethod(kGetSystemAccentColorMethod);
      if (colors == null) return;

      accent = _retrieve(colors['accent'])!;
      light = _retrieve(colors['light']) ?? accent;
      lighter = _retrieve(colors['lighter']) ?? accent;
      lightest = _retrieve(colors['lightest']) ?? accent;
      dark = _retrieve(colors['dark']) ?? accent;
      darker = _retrieve(colors['darker']) ?? accent;
      darkest = _retrieve(colors['darkest']) ?? accent;
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
