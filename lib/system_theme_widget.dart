import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:system_theme/system_theme.dart';

typedef ThemeWidgetBuilder = Widget Function(
  BuildContext context,
  SystemAccentColor accent,
);

class SystemThemedWidget extends StatelessWidget {
  final ThemeWidgetBuilder builder;

  const SystemThemedWidget({Key? key, required this.builder}) : super(key: key);

  static const _eventChannel =
      EventChannel('system_theme_events/switch_callback');

  static Stream<SystemAccentColor> ThemeStream() {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return SystemAccentColor.fromMap(event);
    }).distinct();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ThemeStream(),
      builder: (context, snapshot) {
        print(snapshot.data);
        var accent = snapshot.data != null
            ? snapshot.data as SystemAccentColor
            : SystemTheme.accentColor;
        return builder(context, accent);
      },
    );
  }
}
