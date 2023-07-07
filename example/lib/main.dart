import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentColor.load();
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    debugPrint(SystemTheme.accentColor.accent.toString());
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      SystemTheme.accentColor.lightest,
      SystemTheme.accentColor.lighter,
      SystemTheme.accentColor.light,
      SystemTheme.accentColor.accent,
      SystemTheme.accentColor.dark,
      SystemTheme.accentColor.darker,
      SystemTheme.accentColor.darkest,
    ];
    return Scaffold(
      body: Column(
        children: colors.map((color) {
          return Expanded(
            child: Container(
              color: color,
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                [
                  'Lightest',
                  'Lighter',
                  'Light',
                  'Default',
                  'Dark',
                  'Darker',
                  'Darkest',
                ][colors.indexOf(color)],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color.computeLuminance() >= 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
