<div>
  <h1 align="center">system_theme</h1>
  <p align="center" >
    <a title="Discord" href="https://discord.gg/674gpDQUVq">
      <img src="https://img.shields.io/discord/809528329337962516?label=discord&logo=discord" />
    </a>
    <a title="Pub" href="https://pub.dartlang.org/packages/system_theme" >
      <img src="https://img.shields.io/pub/v/system_theme.svg?style=popout&include_prereleases" />
    </a>
    <a title="Github License">
      <img src="https://img.shields.io/github/license/bdlukaa/system_theme" />
    </a>
  </p>
  <p align="center">
  A flutter plugin to get the current system theme information
  </p>
</div>

### Platforms

| Feature          | Android | iOS | Web | Windows | Linux |
| ---------------- | ------- | --- | --- | ------- | ----- |
| Get accent color | ✔️      |     | ✔️  | ✔️      |       |
| Get dark mode    | ✔️      | ✔️  | ✔️  | ✔️      |       |

## Usage

Import it:

```dart
import 'package:system_theme/system_theme.dart';
```

### Get system accent color

Use the getter `SystemTheme.accentInstance.accent` to get the system accent color.

```dart
final accentColor = SystemTheme.accentInstance.accent;
```

To reload the accent colors, use the method `load()`:

```dart
await SystemTheme.accentInstance.load();
```

You can load the colors on main, so the colors can't be wrong at runtime:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentInstance.load();
  runApp(MyApp());
}
```

### Check dark mode

Use the getter `SystemTheme.isDarkMode` to check if the device is in dark mode.

```dart
final darkMode = SystemTheme.darkMode;
```

# Contribution

Feel free to [open an issue](https://github.com/bdlukaa/system_theme/issues/new) if you find an error or [make pull requests](https://github.com/bdlukaa/system_theme/pulls).

## Acknowlegments

- [@alexmercerind](https://github.com/alexmercerind) for the Windows implementation
