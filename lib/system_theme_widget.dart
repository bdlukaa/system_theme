import 'package:flutter/widgets.dart';
import 'package:system_theme/system_theme.dart';

typedef ThemeWidgetBuilder = Widget Function(
  BuildContext context,
  SystemAccentColor accent,
);

class SystemThemedWidget extends StatelessWidget {
  final ThemeWidgetBuilder builder;

  const SystemThemedWidget({Key? key, required this.builder}) : super(key: key);

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
