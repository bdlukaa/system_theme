#include "include/system_theme/system_theme_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

#include <SystemTheme/Windows10Colors-master/Windows10Colors/Windows10Colors.cpp>

flutter::EncodableMap getRGBA(windows10colors::RGBA _color) {
    /* Converts windows10colors::RGBA to Flutter readable map of following structure.
     *
     * {
     *      'R': 0,
     *      'G': 120,
     *      'B': 215,
     *      'A': 1
     * }
     * 
     */
    using namespace windows10colors;
    flutter::EncodableMap color = flutter::EncodableMap();
    color[flutter::EncodableValue("R")] = flutter::EncodableValue(static_cast<int>(GetRValue(_color)));
    color[flutter::EncodableValue("G")] = flutter::EncodableValue(static_cast<int>(GetGValue(_color)));
    color[flutter::EncodableValue("B")] = flutter::EncodableValue(static_cast<int>(GetBValue(_color)));
    color[flutter::EncodableValue("A")] = flutter::EncodableValue(static_cast<int>(GetAValue(_color)));
    return color;
}

namespace {

class SystemThemePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SystemThemePlugin();

  virtual ~SystemThemePlugin();

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void SystemThemePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "system_theme",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<SystemThemePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

SystemThemePlugin::SystemThemePlugin() {}

SystemThemePlugin::~SystemThemePlugin() {}

void SystemThemePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "SystemTheme.darkMode") {
            bool darkMode = false;
            windows10colors::GetDarkModeEnabled(darkMode);
            result->Success(flutter::EncodableValue(darkMode));
        }
        else if (method_call.method_name() == "SystemTheme.accentColor") {
            windows10colors::AccentColor accentColors;
            windows10colors::GetAccentColor(accentColors);
            flutter::EncodableMap colors = flutter::EncodableMap();
            colors[flutter::EncodableValue("accent")] = flutter::EncodableValue(
                getRGBA(accentColors.accent)
            );
            colors[flutter::EncodableValue("light")] = flutter::EncodableValue(
                getRGBA(accentColors.light)
            );
            colors[flutter::EncodableValue("lighter")] = flutter::EncodableValue(
                getRGBA(accentColors.lighter)
            );
            colors[flutter::EncodableValue("lightest")] = flutter::EncodableValue(
                getRGBA(accentColors.lightest)
            );
            colors[flutter::EncodableValue("dark")] = flutter::EncodableValue(
                getRGBA(accentColors.dark)
            );
            colors[flutter::EncodableValue("darker")] = flutter::EncodableValue(
                getRGBA(accentColors.darker)
            );
            colors[flutter::EncodableValue("darkest")] = flutter::EncodableValue(
                getRGBA(accentColors.darkest)
            );
            result->Success(flutter::EncodableValue(colors));
        }
        else {
            result->NotImplemented();
        }
}

}  // namespace

void SystemThemePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  SystemThemePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
