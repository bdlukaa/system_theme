import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart'
    show Color, EventChannel, MethodChannel, MissingPluginException;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;

export 'system_theme_builder.dart';

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
  /// Platform channel handler for invoking native methods.
  static const MethodChannel _channel = MethodChannel('system_theme');

  static const getSystemAccentColorMethodName = 'SystemTheme.accentColor';

  /// Platform event channel handler for system theme changes.
  static const _eventChannel = EventChannel(
    'system_theme_events/switch_callback',
  );

  static StreamSubscription<dynamic>? _eventSubscription;

  static final StreamController<SystemAccentColor> _onChangeController =
      StreamController<SystemAccentColor>.broadcast(
        onListen: _listenForChanges,
        onCancel: _stopListeningForChanges,
      );
  static final Stream<SystemAccentColor> _onChangeStream = _onChangeController
      .stream
      .distinct();

  static void _listenForChanges() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      _onChangeController.add(SystemAccentColor._fromMap(event));
    });
  }

  static Future<void> _stopListeningForChanges() async {
    final subscription = _eventSubscription;
    _eventSubscription = null;
    await subscription?.cancel();
  }

  /// Default system accent color.
  static const kDefaultFallbackColor = Color(0xff00b7c3);

  /// The color used for accent shades when system colors are unavailable.
  ///
  /// Changing this value updates [accentColor] immediately if it has not yet
  /// loaded native colors. Successfully loaded native colors are preserved;
  /// the new fallback is used if a later load cannot provide system colors.
  static Color _fallbackColor = kDefaultFallbackColor;
  static Color get fallbackColor => _fallbackColor;
  static set fallbackColor(Color color) {
    _fallbackColor = color;
    _accentColor?._setFallbackColor(color);
  }

  static SystemAccentColor? _accentColor;

  /// Whether to automatically adjust lightness if the color if the platform
  /// doesn't support it natively.
  ///
  /// Enabled by default.
  static bool autoAdjustLightness = true;

  /// Get the system accent color.
  ///
  /// The color is available immediately with [fallbackColor]. Reading this
  /// property does not perform platform I/O; call [SystemAccentColor.load] to
  /// fetch the system color.
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
  static SystemAccentColor get accentColor =>
      _accentColor ??= SystemAccentColor(fallbackColor);

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

    return _onChangeStream;
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
  Future<void>? _loadFuture;

  /// The accent color used when the others are not available.
  Color _defaultAccentColor;
  Color get defaultAccentColor => _defaultAccentColor;
  bool _hasLoadedSystemColors = false;

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

  SystemAccentColor(this._defaultAccentColor) {
    accent = _defaultAccentColor;
    light = _defaultAccentColor;
    lighter = _defaultAccentColor;
    lightest = _defaultAccentColor;
    dark = _defaultAccentColor;
    darker = _defaultAccentColor;
    darkest = _defaultAccentColor;
  }

  SystemAccentColor._fromMap(dynamic colors)
    : _defaultAccentColor = SystemTheme.fallbackColor {
    accent = _defaultAccentColor;
    light = _defaultAccentColor;
    lighter = _defaultAccentColor;
    lightest = _defaultAccentColor;
    dark = _defaultAccentColor;
    darker = _defaultAccentColor;
    darkest = _defaultAccentColor;
    _retrieveFromColors(colors);
  }

  void _setFallbackColor(Color color) {
    _defaultAccentColor = color;
    if (_hasLoadedSystemColors) return;

    accent = color;
    light = color;
    lighter = color;
    lightest = color;
    dark = color;
    darker = color;
    darkest = color;
  }

  /// Fetches the system accent colors.
  ///
  /// Concurrent calls share the same operation. Errors from this explicit
  /// operation are propagated to its callers, except [MissingPluginException],
  /// which leaves this color set to its fallback.
  Future<void> load() {
    return _loadFuture ??= _load().whenComplete(() => _loadFuture = null);
  }

  Future<void> _load() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final colors = await SystemTheme._channel.invokeMethod(
        SystemTheme.getSystemAccentColorMethodName,
      );
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
    final systemAccent = _retrieve(colors['accent']);
    _hasLoadedSystemColors = systemAccent != null;
    accent = systemAccent ?? defaultAccentColor;

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

  /// Releases any used resources.
  ///
  /// The object can be loaded again after disposal.
  void dispose() {
    final subscription = _subscription;
    _subscription = null;
    subscription?.cancel();
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
