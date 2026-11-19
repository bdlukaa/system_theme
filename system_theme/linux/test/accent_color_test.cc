#include "../accent_color.h"

#include <iostream>
#include <limits>

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

bool tracks_initial_and_repeated_color_state() {
  SystemThemeColorState state = {};
  system_theme_color_state_reset(&state);

  SystemThemeColor blue = {10, 20, 30, 255};
  return expect(system_theme_color_state_update(&state, true, blue),
                "expected first color update to emit") &&
         expect(state.has_color && system_theme_color_equals(state.color, blue),
                "expected state to store first color") &&
         expect(!system_theme_color_state_update(&state, true, blue),
                "expected identical color update to be deduplicated");
}

bool detects_changes_in_any_channel() {
  SystemThemeColorState state = {};
  system_theme_color_state_reset(&state);

  SystemThemeColor base = {10, 20, 30, 255};
  if (!expect(system_theme_color_state_update(&state, true, base),
              "expected initial update")) {
    return false;
  }

  SystemThemeColor changed_red = {11, 20, 30, 255};
  SystemThemeColor changed_green = {11, 21, 30, 255};
  SystemThemeColor changed_blue = {11, 21, 31, 255};
  SystemThemeColor changed_alpha = {11, 21, 31, 200};

  return expect(system_theme_color_state_update(&state, true, changed_red),
                "expected red channel change to emit") &&
         expect(system_theme_color_state_update(&state, true, changed_green),
                "expected green channel change to emit") &&
         expect(system_theme_color_state_update(&state, true, changed_blue),
                "expected blue channel change to emit") &&
         expect(system_theme_color_state_update(&state, true, changed_alpha),
                "expected alpha channel change to emit");
}

bool preserves_last_known_color_when_lookup_fails() {
  SystemThemeColorState state = {};
  system_theme_color_state_reset(&state);

  SystemThemeColor first = {10, 20, 30, 255};
  SystemThemeColor ignored = {99, 99, 99, 255};
  SystemThemeColor second = {40, 50, 60, 255};

  return expect(system_theme_color_state_update(&state, true, first),
                "expected initial color") &&
         expect(!system_theme_color_state_update(&state, false, ignored),
                "expected unavailable lookup not to emit") &&
         expect(state.has_color && system_theme_color_equals(state.color, first),
                "expected unavailable lookup to preserve last color") &&
         expect(!system_theme_color_state_update(&state, true, first),
                "expected returning same color after failure not to emit") &&
         expect(system_theme_color_state_update(&state, true, second),
                "expected new color after failure to emit");
}

bool reset_clears_tracked_color() {
  SystemThemeColorState state = {};
  system_theme_color_state_reset(&state);

  SystemThemeColor color = {10, 20, 30, 255};
  if (!expect(system_theme_color_state_update(&state, true, color),
              "expected initial color")) {
    return false;
  }

  system_theme_color_state_reset(&state);
  return expect(!state.has_color, "expected reset to clear has_color") &&
         expect(system_theme_color_state_update(&state, true, color),
                "expected same color to emit after reset");
}

bool converts_portal_rgb_with_rounding() {
  SystemThemeColor color = {};
  if (!expect(system_theme_portal_rgb_to_color(53.0 / 255.0, 132.0 / 255.0,
                                               228.0 / 255.0, &color),
              "expected portal GNOME blue conversion") ||
      !expect(color.red == 53 && color.green == 132 && color.blue == 228 &&
                  color.alpha == 255,
              "unexpected portal GNOME blue RGB channels")) {
    return false;
  }

  if (!expect(system_theme_portal_rgb_to_color(29.0 / 255.0, 0.0, 1.0, &color),
              "expected portal rounding conversion") ||
      !expect(color.red == 29 && color.green == 0 && color.blue == 255 &&
                  color.alpha == 255,
              "unexpected rounded portal channels")) {
    return false;
  }

  return true;
}

bool rejects_invalid_portal_rgb_without_mutation() {
  const SystemThemeColor sentinel = {1, 2, 3, 4};
  SystemThemeColor color = sentinel;
  const double nan = std::numeric_limits<double>::quiet_NaN();
  const double inf = std::numeric_limits<double>::infinity();

  return expect(!system_theme_portal_rgb_to_color(-0.01, 0.5, 0.5, &color),
                "expected negative channel rejection") &&
         expect(!system_theme_portal_rgb_to_color(0.5, 1.01, 0.5, &color),
                "expected >1 channel rejection") &&
         expect(!system_theme_portal_rgb_to_color(0.5, 0.5, nan, &color),
                "expected NaN channel rejection") &&
         expect(!system_theme_portal_rgb_to_color(inf, 0.5, 0.5, &color),
                "expected Inf channel rejection") &&
         expect(system_theme_color_equals(color, sentinel),
                "expected invalid portal RGB not to mutate output");
}

bool maps_gnome_accent_names() {
  struct Case {
    const char* name;
    SystemThemeColor expected;
  };
  const Case kCases[] = {
      {"blue", {53, 132, 228, 255}},   {"teal", {33, 144, 164, 255}},
      {"green", {58, 148, 74, 255}},   {"yellow", {200, 136, 0, 255}},
      {"orange", {237, 91, 0, 255}},   {"red", {230, 45, 66, 255}},
      {"pink", {213, 97, 153, 255}},   {"purple", {145, 65, 172, 255}},
      {"slate", {111, 131, 150, 255}},
  };

  for (const auto& entry : kCases) {
    SystemThemeColor color = {};
    if (!expect(system_theme_gnome_accent_name_to_color(entry.name, &color),
                "expected GNOME accent name match") ||
        !expect(system_theme_color_equals(color, entry.expected),
                "unexpected GNOME accent RGB channels")) {
      return false;
    }
  }

  const SystemThemeColor sentinel = {9, 8, 7, 6};
  SystemThemeColor unknown = sentinel;
  return expect(!system_theme_gnome_accent_name_to_color(nullptr, &unknown),
                "expected nullptr GNOME name rejection") &&
         expect(!system_theme_gnome_accent_name_to_color("unknown", &unknown),
                "expected unknown GNOME name rejection") &&
         expect(system_theme_color_equals(unknown, sentinel),
                "expected invalid GNOME name not to mutate output");
}

}  // namespace

int main() {
  if (!converts_rgba_channels() ||
      !preserves_fallback_when_accent_is_unavailable() ||
      !tracks_initial_and_repeated_color_state() ||
      !detects_changes_in_any_channel() ||
      !preserves_last_known_color_when_lookup_fails() ||
      !reset_clears_tracked_color() ||
      !converts_portal_rgb_with_rounding() ||
      !rejects_invalid_portal_rgb_without_mutation() ||
      !maps_gnome_accent_names()) {
    return 1;
  }
  return 0;
}
