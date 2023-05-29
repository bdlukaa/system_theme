#include "include/system_theme/system_theme_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "system_theme_plugin.h"

void SystemThemePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  system_theme::SystemThemePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
