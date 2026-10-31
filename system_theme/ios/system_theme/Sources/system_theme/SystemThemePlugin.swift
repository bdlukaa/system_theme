import Flutter
import SwiftUI
import UIKit

public class SystemThemePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "system_theme", binaryMessenger: registrar.messenger())
        let instance = SystemThemePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "SystemTheme.accentColor":
            if #available(iOS 14.0, *) {
                if let accent = Color.accentColor.toHex() {
                    result(["accent": accent])
                } else {
                    result(nil)
                }
            } else {
                result(nil)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

@available(iOS 14.0, *)
extension Color {
    func toHex() -> [String: Int]? {
        let color = UIColor(self).resolvedColor(with: UITraitCollection.current)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if !color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            var white: CGFloat = 0
            guard color.getWhite(&white, alpha: &alpha) else { return nil }
            red = white
            green = white
            blue = white
        }

        let components = [red, green, blue, alpha]
        guard components.allSatisfy({ $0.isFinite }) else { return nil }
        let channels = components.map { Int((min(max($0, 0), 1) * 255).rounded()) }
        return ["R": channels[0], "G": channels[1], "B": channels[2], "A": channels[3]]
    }
}
