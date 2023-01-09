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
    <a title="Patreon" href="https://patreon.com/bdlukaa">
      <img src="https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-patreon.vercel.app%2Fapi%3Fusername%3Dbdlukaa%26type%3Dpatrons&style=for-the-badge">
    </a>
  </p>
  <p align="center">
  A flutter plugin to get the current system theme information
  </p>
</div>

- [Supported platforms](#supported-platforms)
- [Usage](#usage)
  - [Get system accent color](#get-system-accent-color)
  - [Check dark mode](#check-dark-mode)
- [Contribution](#contribution)
  - [Acknowlegments](#acknowlegments)

### Supported platforms

| Feature          | Android 10+ | iOS | Web | MacOs 10.4+ | Windows 10+ and XBox | Linux GTK 3+ |
| ---------------- | :---------: | :-: | :-: | :---------: | :------------------: | :----------: |
| Get accent color |     ✔️      |     | ✔️  |     ✔️      |          ✔️          |      ✔️      |
| Get dark mode    |     ✔️      | ✔️  | ✔️  |     ✔️      |          ✔️          |      ✔️      |

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

You can load the colors before running the app, so the colors can't be wrong at runtime:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentInstance.load();
  runApp(MyApp());
}
```

### Configure a fallback accent color

To avoid unexpected effects at runtime, it's good to configure a fallback color. A fallback color is used if the system was not able to provide the color

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemTheme.fallbackColor = const Color(0xFF865432);
  await SystemTheme.accentInstance.load();

  runApp(MyApp());
}
```

### Check dark mode

Use the getter `SystemTheme.isDarkMode` to check if the device is in dark mode.

```dart
final darkMode = SystemTheme.darkMode;
```

## Contribution

Feel free to [open an issue](https://github.com/bdlukaa/system_theme/issues/new) if you find an error or [make pull requests](https://github.com/bdlukaa/system_theme/pulls).

### Acknowlegments

- [@alexmercerind](https://github.com/alexmercerind) for the Windows implementation
