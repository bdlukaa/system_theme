import Flutter
import SwiftUI

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
                var colors:[String:[String:Int]?] = [:]
                colors["accent"] = Color.accentColor.toHex()
                result(colors)
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
    // Function to convert SwiftUI Color to a Hex String
    func toHex() -> Dictionary<String,Int>? {
        // Extract the RGBA components from the Color
        let components = self.cgColorComponents
        // Check if components contain at least RGB
        guard components.count >= 3 else { return nil }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let a = components.count >= 4 ? components[3] : 1.0
        
        return [
            "R":lroundf(Float(r * 255)),
            "G":lroundf(Float(g * 255)),
            "B":lroundf(Float(b * 255)),
            "A":lroundf(Float(a * 255))
        ]
    }
    
    // Helper function to extract RGBA components
    private var cgColorComponents: [CGFloat] {
        // Convert SwiftUI Color to UIColor
        let uiColor = UIColor(self)
        
        // Get CGColor and its components
        guard let components = uiColor.cgColor.components else {
            return []
        }

        // Handle the case of grayscale color (1 component)
        if components.count == 2 {
            return [components[0], components[0], components[0], components[1]]
        }
        
        return components
    }
}
