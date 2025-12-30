import Cocoa
import FlutterMacOS

public class SystemThemePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SystemThemePlugin()

        let methodChannel = FlutterMethodChannel(name: "system_theme", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(name: "system_theme_events/switch_callback", binaryMessenger: registrar.messenger)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "SystemTheme.accentColor":
            result(getCurrentAccentColorMap())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        if #available(macOS 10.14, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(systemColorsDidChange),
                name: NSNotification.Name("NSSystemColorsDidChangeNotification"),
                object: nil
            )
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        self.eventSink = nil
        return nil
    }

    @objc func systemColorsDidChange(_ notification: Notification) {
        if let colors = getCurrentAccentColorMap() {
            eventSink?(colors)
        }
    }

    private func getCurrentAccentColorMap() -> [String: Any]? {
        if #available(macOS 10.14, *) {
            // Need to specify sRGB to get component values compatible with Flutter
            guard let color = NSColor.controlAccentColor.usingColorSpace(.sRGB) else {
                return nil
            }

            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)

            let rgba: [String: Any] = [
                "R": Int(r * 255),
                "G": Int(g * 255),
                "B": Int(b * 255),
                "A": Int(a * 255)
            ]

            return ["accent": rgba]
        }
        return nil
    }
}
