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
    <a title="PRs are welcome">
      <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" />
    </a>
  </p>
  <p align="center">
    <a title="Buy me a coffee" href="https://www.buymeacoffee.com/bdlukaa">
      <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=bdlukaa&button_colour=FF5F5F&font_colour=ffffff&font_family=Lato&outline_colour=000000&coffee_colour=FFDD00">
    </a>
  </p>
  <p align="center">
  A plugin to get the current system theme info
  </p>
</div>

### Platoforms

✔️ Windows

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
SystemTheme.accentInstance.load();
```

### Check dark mode

```dart
final darkMode = await SystemTheme.darkMode;
```

# Contribution

Feel free to [open an issue](https://github.com/bdlukaa/system_theme/issues/new) if you find an error or [make pull requests](https://github.com/bdlukaa/system_theme/pulls).
