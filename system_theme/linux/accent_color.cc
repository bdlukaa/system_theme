#include "accent_color.h"

bool system_theme_rgba_to_color(bool found, double red, double green,
                                double blue, double alpha,
                                SystemThemeColor* color) {
  if (!found) return false;

  color->red = static_cast<int>(red * 255);
  color->green = static_cast<int>(green * 255);
  color->blue = static_cast<int>(blue * 255);
  color->alpha = static_cast<int>(alpha * 255);
  return true;
}
