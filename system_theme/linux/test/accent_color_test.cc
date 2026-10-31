#include "../accent_color.h"

#include <iostream>

namespace {

bool expect(bool condition, const char* message) {
  if (condition) return true;
  std::cerr << message << '\n';
  return false;
}

bool converts_rgba_channels() {
  SystemThemeColor color;
  return expect(system_theme_rgba_to_color(true, 0.5, 0.25, 0.75, 1.0, &color),
                "expected an accent color") &&
         expect(color.red == 127, "unexpected red channel") &&
         expect(color.green == 63, "unexpected green channel") &&
         expect(color.blue == 191, "unexpected blue channel") &&
         expect(color.alpha == 255, "unexpected alpha channel");
}

bool preserves_fallback_when_accent_is_unavailable() {
  SystemThemeColor fallback = {1, 2, 3, 4};
  return expect(!system_theme_rgba_to_color(false, 0.0, 0.0, 0.0, 0.0, &fallback),
                "expected no accent color") &&
         expect(fallback.red == 1 && fallback.green == 2 && fallback.blue == 3 &&
                    fallback.alpha == 4,
                "unexpected fallback color mutation");
}

}  // namespace

int main() {
  if (!converts_rgba_channels() ||
      !preserves_fallback_when_accent_is_unavailable()) {
    return 1;
  }
  return 0;
}
