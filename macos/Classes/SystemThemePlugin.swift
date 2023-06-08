import Cocoa
import FlutterMacOS

private let kAppleInterfaceThemeChangedNotification = "AppleInterfaceThemeChangedNotification"
private let kAppleInterfaceStyle = "AppleInterfaceStyle"
private let kAppleInterfaceStyleSwitchesAutomatically = "AppleInterfaceStyleSwitchesAutomatically"

public class SystemThemePlugin: NSObject, FlutterPlugin {
	public static func register(with registrar: FlutterPluginRegistrar) {
		let channel = FlutterMethodChannel(name: "system_theme", binaryMessenger: registrar.messenger)
		let instance = SystemThemePlugin()
		registrar.addMethodCallDelegate(instance, channel: channel)
	}
	
	func getAppearance(): String {
        var osAppearance = "Light"
        if #available(OSX 10.15, *) {
            let appearanceDescription = NSApplication.shared.effectiveAppearance.debugDescription.lowercased()
            self.textview.textStorage?.append(NSAttributedString(string: "appearanceDescription: \(appearanceDescription)\n"))
            if appearanceDescription.contains("dark") {
                self.osAppearance = "Dark"
            }
        } else if #available(OSX 10.14, *) {
            if let appleInterfaceStyle = UserDefaults.standard.object(forKey: kAppleInterfaceStyle) as? String {
                self.textview.textStorage?.append(NSAttributedString(string: "appleInterfaceStyle: \(appleInterfaceStyle)\n"))
                if appleInterfaceStyle.lowercased().contains("dark") {
                    self.osAppearance = "Dark"
                }
            }
        }
		return osAppearance;
    }

	public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		switch call.method {
		case "SystemTheme.darkMode":
			result(getAppearance() == "Dark");
		case "SystemTheme.accentColor":
			if #available(macOS 10.14, *) {
				if let color = NSColor.controlAccentColor.usingColorSpace(.sRGB) {
					var r: CGFloat = 0;
					var g: CGFloat = 0;
					var b: CGFloat = 0;
					var a: CGFloat = 0;
					color.getRed(&r, green: &g, blue: &b, alpha: &a);

					var map: Dictionary<String, Any> = Dictionary()
					map["R"] = Int(r * 255);
					map["G"] = Int(g * 255);
					map["B"] = Int(b * 255);
					map["A"] = Int(a * 255);

					var colors: Dictionary<String, Any> = Dictionary()
					colors["accent"] = map;
					// other colors here

					result(colors);

				} else {
					result(nil);
				}
			} else {
				result(nil);
			}
		default:
			result(FlutterMethodNotImplemented)
		}
	}
}
