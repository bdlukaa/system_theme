# system_theme_web

[system_theme](https://pub.dev/packages/system_theme) implementation for the web.

## Browser accent colors

The web plugin reads the browser's CSS [`AccentColor`](https://developer.mozilla.org/en-US/docs/Web/CSS/system-color) system color, with `accent-color: auto`, when the browser supports it. This represents the browser's accent for UI controls, **not a guaranteed native OS accent color**. The CSS `Highlight` color is for selections and is not used as an accent fallback.

Browsers may return a fixed or browser-selected value instead of the user's OS choice to reduce fingerprinting. Forced-colors mode, browser and OS settings, and browser support can also affect the result. There is no reliable way for a web page to tell whether a returned `AccentColor` matches the native accent. In particular, [`accent-color: auto`](https://developer.mozilla.org/en-US/docs/Web/CSS/accent-color) can remain `auto` in computed styles and does not expose a reliable native color on its own.

If `AccentColor` is unsupported or cannot be resolved, the plugin returns no color. `SystemAccentColor.load()` then retains its current palette: the configured `SystemTheme.fallbackColor` before a successful load, or the last successfully loaded palette on refresh. The plugin does not invent browser-specific color values. See the [CSS Color specification](https://drafts.csswg.org/css-color-4/#css-system-colors) for the privacy considerations.

To compare behavior manually, run the example in Chrome, Firefox, and Safari/WebKit, record the returned color, then change the OS accent and reload in each browser. A color that stays fixed is valid browser privacy behavior and must not be interpreted as proof of the OS accent.
