#include "accent_color.h"

#include <cmath>
#include <cstring>

namespace {

bool is_valid_unit_channel(double value) {
  return std::isfinite(value) && value >= 0.0 && value <= 1.0;
}

}  // namespace

bool system_theme_rgba_to_color(bool found, double red, double green,
                                double blue, double alpha,
                                SystemThemeColor* color) {
  if (!found || color == nullptr) return false;

  color->red = static_cast<int>(red * 255);
  color->green = static_cast<int>(green * 255);
  color->blue = static_cast<int>(blue * 255);
  color->alpha = static_cast<int>(alpha * 255);
  return true;
}

bool system_theme_portal_rgb_to_color(double red, double green, double blue,
                                      SystemThemeColor* color) {
  if (color == nullptr || !is_valid_unit_channel(red) ||
      !is_valid_unit_channel(green) || !is_valid_unit_channel(blue)) {
    return false;
  }

  color->red = static_cast<int>(std::lround(red * 255.0));
  color->green = static_cast<int>(std::lround(green * 255.0));
  color->blue = static_cast<int>(std::lround(blue * 255.0));
  color->alpha = 255;
  return true;
}

bool system_theme_gnome_accent_name_to_color(const char* name,
                                             SystemThemeColor* color) {
  if (name == nullptr || color == nullptr) return false;

  struct Entry {
    const char* name;
    SystemThemeColor color;
  };
  static const Entry kEntries[] = {
      {"blue", {53, 132, 228, 255}},
      {"teal", {33, 144, 164, 255}},
      {"green", {58, 148, 74, 255}},
      {"yellow", {200, 136, 0, 255}},
      {"orange", {237, 91, 0, 255}},
      {"red", {230, 45, 66, 255}},
      {"pink", {213, 97, 153, 255}},
      {"purple", {145, 65, 172, 255}},
      {"slate", {111, 131, 150, 255}},
  };

  for (const auto& entry : kEntries) {
    if (std::strcmp(name, entry.name) == 0) {
      *color = entry.color;
      return true;
    }
  }
  return false;
}

bool system_theme_color_equals(const SystemThemeColor& lhs,
                               const SystemThemeColor& rhs) {
  return lhs.red == rhs.red && lhs.green == rhs.green &&
         lhs.blue == rhs.blue && lhs.alpha == rhs.alpha;
}

void system_theme_color_state_reset(SystemThemeColorState* state) {
  if (state == nullptr) return;
  state->has_color = false;
  state->color = {0, 0, 0, 0};
}

bool system_theme_color_state_update(SystemThemeColorState* state,
                                     bool found,
                                     const SystemThemeColor& color) {
  if (state == nullptr || !found) return false;
  if (state->has_color && system_theme_color_equals(state->color, color)) {
    return false;
  }

  state->has_color = true;
  state->color = color;
  return true;
}
