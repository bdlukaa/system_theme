import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentInstance.load();
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    print(SystemTheme.accentInstance.accent);
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      SystemTheme.accentInstance.lightest,
      SystemTheme.accentInstance.lighter,
      SystemTheme.accentInstance.light,
      SystemTheme.accentInstance.accent,
      SystemTheme.accentInstance.dark,
      SystemTheme.accentInstance.darker,
      SystemTheme.accentInstance.darkest,
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
                style: Theme.of(context).textTheme.headline6?.copyWith(
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
