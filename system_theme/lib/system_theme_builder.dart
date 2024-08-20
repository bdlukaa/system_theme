import 'package:flutter/widgets.dart';
import 'package:system_theme/system_theme.dart';

typedef ThemeWidgetBuilder = Widget Function(
  BuildContext context,
  SystemAccentColor accent,
);

/// A widget that rebuilds when the system theme changes.
///
/// ```dart
/// SystemThemeBuilder(builder: (context, accent) {
///  return ColoredBox(color: accent.accent);
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
  const SystemThemeBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SystemAccentColor>(
      stream: SystemTheme.onChange,
      builder: (context, snapshot) {
        return builder(context, snapshot.data ?? SystemTheme.accentColor);
      },
    );
  }
}
