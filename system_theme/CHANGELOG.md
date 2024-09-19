## [3.1.1] - [19/09/2024]

* Fix Android build ([#35](https://github.com/bdlukaa/system_theme/pull/35), [#36](https://github.com/bdlukaa/system_theme/pull/36))

## [3.1.0] - [20/08/2024]

* [Migrate](https://dart.dev/interop/js-interop/package-web) to `package:web` over `dart:html` on web to enable WASM compatibility
* Support RGBA colors on web ([#31](https://github.com/bdlukaa/system_theme/issues/31))
* Use `compileSdkVersion` version `31` on Android ([#34](https://github.com/bdlukaa/system_theme/issues/34))

## [3.0.0] - [03/07/2024]

* Add support for iOS ([#32](https://github.com/bdlukaa/system_theme/pull/32))

## [2.3.1] - [20/07/2023]

- Fix late initialization bug when using the `onChange` stream on platforms other than Windows ([#29](https://github.com/bdlukaa/system_theme/issues/29))

## [2.3.0] - [08/07/2023]

- **BREAKING** Removed `SystemTheme.darkMode` ([#24](https://github.com/bdlukaa/system_theme/pull/24))
- Prevent app breaks on loading accent color failed ([#19](https://github.com/bdlukaa/system_theme/pull/19))
- React to changes in the accent color on Windows ([#7](https://github.com/bdlukaa/system_theme/pull/7))
- Added TargetPlatform.supportsAccentColor helper ([#26](https://github.com/bdlukaa/system_theme/pull/26))

## [2.2.0] - [03/06/2023]

- Fix app build on Android ([#14](https://github.com/bdlukaa/system_theme/issues/14))

## [2.1.0] - [09/01/2023]

- Bundle source code with the package for Windows ([#8](https://github.com/bdlukaa/system_theme/issues/8))
- Added `SystemTheme.fallbackColor` ([#9](https://github.com/bdlukaa/system_theme/issues/9))
- Support for Linux and macOS ([#11](https://github.com/bdlukaa/system_theme/pull/11))

## [2.0.0] - Breaking Changes - 03/04/2022

- **BREAKING** `darkMode` was renamed to `isDarkMode`, and it's now sync
- **BREAKING** `accentInstance` was renamed to `accentColor`
- `SystemAccentColor` is now an extension of `Color`

## [1.0.1] - 12/05/2021

- Remove external C++ source present in the repository ([#1](https://github.com/bdlukaa/system_theme/pull/1))
- Improved the example app

## [1.0.0] - Initial - 01/04/2021

- Get system accent color
- Check if system is in dark mode
