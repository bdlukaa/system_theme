import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    SystemTheme.darkMode.then((value) {
      print(value);
    });
    print(SystemTheme.accentInstance.accent);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: SystemTheme.accentInstance.accent,
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
      ),
    );
  }
}
