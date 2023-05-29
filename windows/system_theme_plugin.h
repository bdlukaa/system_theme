#ifndef FLUTTER_PLUGIN_SYSTEM_THEME_PLUGIN_H_
#define FLUTTER_PLUGIN_SYSTEM_THEME_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace system_theme {

class SystemThemePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SystemThemePlugin();

  virtual ~SystemThemePlugin();

  // Disallow copy and assign.
  SystemThemePlugin(const SystemThemePlugin&) = delete;
  SystemThemePlugin& operator=(const SystemThemePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace system_theme

#endif  // FLUTTER_PLUGIN_SYSTEM_THEME_PLUGIN_H_
