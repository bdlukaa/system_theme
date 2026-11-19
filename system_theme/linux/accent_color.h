#ifndef SYSTEM_THEME_ACCENT_COLOR_H_
#define SYSTEM_THEME_ACCENT_COLOR_H_

struct SystemThemeColor {
  int red;
  int green;
  int blue;
  int alpha;
};

struct SystemThemeColorState {
  bool has_color;
  SystemThemeColor color;
};

bool system_theme_rgba_to_color(bool found, double red, double green,
                                double blue, double alpha,
                                SystemThemeColor* color);

bool system_theme_portal_rgb_to_color(double red, double green, double blue,
                                      SystemThemeColor* color);

bool system_theme_gnome_accent_name_to_color(const char* name,
                                             SystemThemeColor* color);

bool system_theme_color_equals(const SystemThemeColor& lhs,
                               const SystemThemeColor& rhs);

void system_theme_color_state_reset(SystemThemeColorState* state);

bool system_theme_color_state_update(SystemThemeColorState* state,
                                     bool found,
                                     const SystemThemeColor& color);

#endif  // SYSTEM_THEME_ACCENT_COLOR_H_
