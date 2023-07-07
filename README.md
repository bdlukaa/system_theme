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
- [Contribution](#contribution)
  - [Acknowlegments](#acknowlegments)

### Supported platforms

| Feature           | Android 10+ | iOS | Web | MacOs 10.4+ | Windows 10+ and XBox | Linux GTK 3+ |
| ----------------- | :---------: | :-: | :-: | :---------: | :------------------: | :----------: |
| Get accent color  |     ✔️      |     | ✔️  |     ✔️      |          ✔️          |      ✔️      |
| Listem to changes |             |     |     |             |          ✔️          |              |

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
SystemThemeBuilder(builder: (context, accent) {
  return ColoredBox(color: accent.accentColor);
});
```

### Checking if accent color is supported

The `flutter/foundation` package provides a `defaultTargetPlatform` getter, which can be used to check what platform the current app is running on.

You can check if the current platform supports accent colors using this extension method:

```dart
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

void main() {
  final supported = defaultTargetPlatform.supportsAccentColor;

  print('Accent color is: ${supported ? 'supported' : 'not supported'} on the current platform');
}
```

## Contribution

Feel free to [open an issue](https://github.com/bdlukaa/system_theme/issues/new) if you find an error or [make pull requests](https://github.com/bdlukaa/system_theme/pulls).

### Acknowlegments

- [@alexmercerind](https://github.com/alexmercerind) for the Windows implementation
- [@pgiacomo69](https://github.com/pgiacomo69) for the accent color listener
