#ifndef SYSTEM_THEME_THEME_CHANGE_MESSAGE_H_
#define SYSTEM_THEME_THEME_CHANGE_MESSAGE_H_

#include <windows.h>

namespace system_theme {

inline bool IsImmersiveColorSetChange(UINT message, LPARAM l_param) {
  return message == WM_SETTINGCHANGE && l_param != 0 &&
      lstrcmpW(reinterpret_cast<LPCWSTR>(l_param), L"ImmersiveColorSet") == 0;
}

}  // namespace system_theme

#endif  // SYSTEM_THEME_THEME_CHANGE_MESSAGE_H_
