import Cocoa
import FlutterMacOS

public class SystemThemePlugin: NSObject, FlutterPlugin {
	public static func register(with registrar: FlutterPluginRegistrar) {
		let channel = FlutterMethodChannel(name: "system_theme", binaryMessenger: registrar.messenger)
		let instance = SystemThemePlugin()
		registrar.addMethodCallDelegate(instance, channel: channel)
	}

	public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		switch call.method {
		case "getPlatformVersion":
			result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
		case "SystemTheme.darkMode":
			let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
			result(type == "Dark");
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
