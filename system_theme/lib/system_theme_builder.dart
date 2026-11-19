import 'package:flutter/widgets.dart';
import 'package:system_theme/system_theme.dart';

typedef ThemeWidgetBuilder =
    Widget Function(BuildContext context, SystemAccentColor accent);

/// A widget that rebuilds when [SystemTheme.onChange] emits a new accent
/// palette. Windows, macOS, Android, and Linux emit automatic native changes;
/// other platforms update after an explicit [SystemAccentColor.load] call.
///
/// ```dart
/// SystemThemeBuilder(builder: (context, color) {
///  return ColoredBox(color: color.accent);
/// });
/// ```
///
/// See also:
///
///  * [SystemTheme.onChange], the stream used to listen to system theme changes.
class SystemThemeBuilder extends StatelessWidget {
  /// The widget builder.
  final ThemeWidgetBuilder builder;

  /// Creates a system theme builder.
  const SystemThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SystemAccentColor>(
      initialData: SystemTheme.accentColor,
      stream: SystemTheme.onChange,
      builder: (context, snapshot) {
        return builder(context, snapshot.data ?? SystemTheme.accentColor);
      },
    );
  }
}
