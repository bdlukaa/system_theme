#include "theme_change_message.h"

#include <iostream>

namespace {


bool Expect(bool condition, const char* message) {
  if (condition) {
    return true;
  }

  std::cerr << message << '\n';
  return false;
}

bool TestMessageRouting() {
  const wchar_t immersive_color_set[] = L"ImmersiveColorSet";
  const wchar_t unrelated_setting[] = L"WindowsThemeElement";

  return Expect(
      system_theme::IsImmersiveColorSetChange(
          WM_SETTINGCHANGE,
          reinterpret_cast<LPARAM>(immersive_color_set)),
      "ImmersiveColorSet setting changes should be handled") &&
      Expect(
          !system_theme::IsImmersiveColorSetChange(
              WM_SETTINGCHANGE,
              reinterpret_cast<LPARAM>(unrelated_setting)),
          "other setting changes should be ignored") &&
      Expect(
          !system_theme::IsImmersiveColorSetChange(WM_SETTINGCHANGE, 0),
          "setting changes without a setting name should be ignored") &&
      Expect(
          !system_theme::IsImmersiveColorSetChange(
              WM_THEMECHANGED,
              reinterpret_cast<LPARAM>(immersive_color_set)),
          "other Windows messages should be ignored");
}

}  // namespace

int main() {
  if (TestMessageRouting()) {
    return 0;
  }

  return 1;
}
