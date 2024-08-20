import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentColor.load();
  SystemTheme.onChange.listen((color) {
    debugPrint('Accent color changed to ${color.accent}');
  });

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return SystemThemeBuilder(builder: (context, accent) {
      final colors = [
        accent.lightest,
        accent.lighter,
        accent.light,
        accent.accent,
        accent.dark,
        accent.darker,
        accent.darkest,
      ];
      return Scaffold(
        body: Column(children: [
          Text(
              'Accent color: ${defaultTargetPlatform.supportsAccentColor ? 'supported' : 'not supported'}'),
          ...colors.map((color) {
            return Expanded(
              child: Container(
                color: color,
                alignment: Alignment.center,
                child: Text(
                  [
                        'Lightest',
                        'Lighter',
                        'Light',
                        'Default',
                        'Dark',
                        'Darker',
                        'Darkest',
                      ][colors.indexOf(color)] +
                      '\n${color.toHex()}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color.computeLuminance() >= 0.5
                            ? Colors.black
                            : Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ]),
      );
    });
  }
}

extension ColorExtension on Color {
  String toHex() {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2, 8)}';
  }
}
