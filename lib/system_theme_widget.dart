part of  'system_theme.dart';



typedef ThemeWidgetBuilder = Widget Function(BuildContext context, SystemAccentColor accent);



class SystemThemedWidget extends StatelessWidget {

  final ThemeWidgetBuilder builder;
  SystemThemedWidget({Key? key,required this.builder}) : super(key: key);



  static const _eventChannel =
   const EventChannel('system_theme_events/switch_callback');

  static Stream<SystemAccentColor> ThemeStream() {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) {
        return SystemAccentColor.fromMap(event);
  })
        .distinct();
  }



  @override
  Widget build(BuildContext context) {


    return StreamBuilder(
      stream: ThemeStream(),
      builder: (context, snapshot) {
          print(snapshot.data);
          var accent = snapshot.data!=null ? snapshot.data as SystemAccentColor : SystemTheme.accentInstance;
          return builder(context,accent);
        }
    );
  }
}

