#include <map>

#include "include/system_theme/system_theme_plugin.h"
#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <SystemTheme/Windows10Colors-master/Windows10Colors/Windows10Colors.cpp>

#include <mutex>

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

     LRESULT CALLBACK MyWndProc(HWND hWnd, UINT iMessage, WPARAM wParam, LPARAM lParam);
     WNDPROC oldProc;



template<typename T = flutter::EncodableValue>
class MyStreamHandler: public flutter::StreamHandler<T> {
public:
	MyStreamHandler () = default;
	virtual ~MyStreamHandler () = default;

	void on_callback (flutter::EncodableMap _data) {

           /* auto _size=_data.size;
            _data.
            std::unique_lock<std::mutex> _ul (m_mtx);
    		std::vector<uint8_t> _vec;
    		_vec.resize (_size);
    		memcpy (&_vec [0], _data, _size); */

    		/* std::vector<uint8_t> _vec;
            _vec.resize (1);


    		m_value = _data; */
            if (m_sink.get ())
    		    m_sink.get ()->Success (_data);
    	}

	/* void on_callback (uint8_t *_data, size_t _size) {
        if (uint64_t (this) == 0xddddddddddddddddul)
            return;
        std::unique_lock<std::mutex> _ul (m_mtx);
		std::vector<uint8_t> _vec;
		_vec.resize (_size);
		memcpy (&_vec [0], _data, _size);
		m_value = _vec;
        if (m_sink.get ())
		    m_sink.get ()->Success (m_value);
	} */
protected:
	std::unique_ptr<flutter::StreamHandlerError<T>> OnListenInternal (const T *arguments, std::unique_ptr<flutter::EventSink<T>> &&events) override {
        std::unique_lock<std::mutex> _ul (m_mtx);
		m_sink = std::move (events);
        return nullptr;
	}
	std::unique_ptr<flutter::StreamHandlerError<T>> OnCancelInternal (const T *arguments) override {
        std::unique_lock<std::mutex> _ul (m_mtx);
		m_sink.release ();
        return nullptr;
	}
private:
	flutter::EncodableValue m_value;
    std::mutex m_mtx;
	std::unique_ptr<flutter::EventSink<T>> m_sink;
};




    class SystemThemePlugin : public flutter::Plugin {
    public:
        static MyStreamHandler<> *RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);
        MyStreamHandler<> *m_handler;
        SystemThemePlugin();

        virtual ~SystemThemePlugin();


        private:
        void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
        std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> m_event_channel;
    };


    MyStreamHandler<> *SystemThemePlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar) {
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(registrar->messenger(), "system_theme", &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<SystemThemePlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        }
      );

     plugin->m_event_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>> (
               registrar->messenger (), "system_theme_events/switch_callback",
               &flutter::StandardMethodCodec::GetInstance ()
            );
      MyStreamHandler<> *_handler=new MyStreamHandler<> ();
      plugin->m_handler = _handler;
      auto _obj_stm_handle = static_cast<flutter::StreamHandler<flutter::EncodableValue>*> (plugin->m_handler);
      std::unique_ptr<flutter::StreamHandler<flutter::EncodableValue>> _ptr {_obj_stm_handle};
      plugin->m_event_channel->SetStreamHandler (std::move (_ptr));


      registrar->AddPlugin(std::move(plugin));
       HWND handle = GetActiveWindow();
       oldProc = reinterpret_cast<WNDPROC>(GetWindowLongPtr(handle, GWLP_WNDPROC));
       SetWindowLongPtr(handle, GWLP_WNDPROC, (LONG_PTR)MyWndProc);
       OutputDebugString(L"****** SYSTEM_THEME_PLUGIN ******: Message Handle Registered");
       return _handler;
    }

    SystemThemePlugin::SystemThemePlugin() {}

    SystemThemePlugin::~SystemThemePlugin() {}

    flutter::EncodableMap getAccentColor(){
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
                return colors;
    }

  MyStreamHandler<> *_m_handler=nullptr;
    LRESULT CALLBACK MyWndProc(HWND hWnd, UINT iMessage, WPARAM wParam, LPARAM lParam)
          {
            if (iMessage == WM_SETTINGCHANGE)
            {
               OutputDebugString(L"****** SYSTEM_THEME_PLUGIN ******: WM_SETTINGCHANGE called");
               if (!lstrcmp(LPCTSTR(lParam), L"ImmersiveColorSet"))
                       {
                          if (_m_handler!=nullptr) {
                           OutputDebugString(L"- Theme Has Changed\n");
                           _m_handler->on_callback (getAccentColor());

                          }
                          else
                          {
                          OutputDebugString(L" - _m_handler is null\n");
                          }
                       }
                       else
                       {
                         OutputDebugString(L"\n");
                       }



            }

            return oldProc(hWnd, iMessage, wParam, lParam);
          }

    void SystemThemePlugin::HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (method_call.method_name() == "SystemTheme.darkMode") {
            bool darkMode = false;
            windows10colors::GetAppDarkModeEnabled(darkMode);
            result->Success(flutter::EncodableValue(darkMode));
        }
        else if (method_call.method_name() == "SystemTheme.accentColor") {

            result->Success(flutter::EncodableValue(getAccentColor()));
        }
        else {
            result->NotImplemented();
        }
    }





}


void SystemThemePluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
      _m_handler=SystemThemePlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));

}
