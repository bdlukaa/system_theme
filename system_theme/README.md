<div>
  <h3 align="center">system_theme</h3>
  <p align="center" >
    <a title="Discord" href="https://discord.gg/674gpDQUVq">
      <img src="https://img.shields.io/discord/809528329337962516?label=discord&logo=discord" />
    </a>
    <a title="Pub" href="https://pub.dartlang.org/packages/system_theme" >
      <img src="https://img.shields.io/pub/v/system_theme.svg?style=popout&include_prereleases" />
    </a>
  </p>
  <p align="center">
  A flutter plugin to retrieve the current system theme information
  </p>
</div>

### Supported platforms

| Platform | Accent Color | Listen to Changes | Minimum Version |
| :--- | :---: | :---: | :--- |
| **Android** | ✔️ | | Android 10+ |
| **iOS** | ✔️ | | iOS 14+ |
| **Windows** | ✔️ | ✔️ | Windows 10+ |
| **macOS** | ✔️ | ✔️ | Mojave 10.14+ |
| **Linux** | ✔️ | | GTK 3+ |
| **Web** | ✔️ | | All modern browsers |

## Usage

Import it:

```dart
import 'package:system_theme/system_theme.dart';
```

### Get system accent color

Use the getter `SystemTheme.accentColor.accent` to get the system accent color.

```dart
final accentColor = SystemTheme.accentColor.accent;
```

To reload the accent colors, use the method `load()`:

```dart
await SystemTheme.accentColor.load();
```

You can load the colors before running the app, so the colors can't be wrong at runtime:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentColor.load();
  runApp(MyApp());
}
```

### Configure a fallback accent color

To avoid unexpected outcomes at runtime, it's recommended to configure your own fallback color. The fallback color is used if the system is not able to provide the color.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemTheme.fallbackColor = const Color(0xFF865432);
  await SystemTheme.accentColor.load();

  runApp(MyApp());
}
```

### Listen to changes on the system accent color

To simply listen to changes on the system accent color, use the `SystemTheme.onChange` stream:

```dart
SystemTheme.onChange.listen((event) {
  debugPrint('Accent color changed to ${event.accentColor}');
});
```

Alteratively, you can the `SystemThemeBuilder` widget to listen to changes on the system accent color:

```dart
SystemThemeBuilder(
  builder: (context, color) {
    return ColoredBox(
      color: color.accent, // Automatically updates when system theme changes
      child: const Center(
        child: Text('System Accent Color'),
      ),
    );
  },
);
```

## Contribution

Feel free to [open an issue](https://github.com/bdlukaa/system_theme/issues/new) if you find an error or [make pull requests](https://github.com/bdlukaa/system_theme/pulls).

### Acknowlegments

- [@alexmercerind](https://github.com/alexmercerind) for the Windows implementation
- [@pgiacomo69](https://github.com/pgiacomo69) for the accent color listener
- [@HosamHasanRamadan](https://github.com/HosamHasanRamadan) for the iOS implementation
