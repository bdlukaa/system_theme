#ifndef SYSTEM_THEME_ACCENT_COLOR_H_
#define SYSTEM_THEME_ACCENT_COLOR_H_

struct SystemThemeColor {
  int red;
  int green;
  int blue;
  int alpha;
};

bool system_theme_rgba_to_color(bool found, double red, double green,
                                double blue, double alpha,
                                SystemThemeColor* color);

#endif  // SYSTEM_THEME_ACCENT_COLOR_H_
