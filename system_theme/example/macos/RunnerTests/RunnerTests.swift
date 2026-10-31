import Cocoa
import FlutterMacOS
import XCTest
@testable import system_theme

final class RunnerTests: XCTestCase {
  private let systemColorsDidChange = Notification.Name("NSSystemColorsDidChangeNotification")

  func testAccentColorConversionProducesByteChannels() {
    let expectation = expectation(description: "accent color result")

    SystemThemePlugin().handle(
      FlutterMethodCall(methodName: "SystemTheme.accentColor", arguments: nil)
    ) { result in
      defer { expectation.fulfill() }

      guard let accent = (result as? [String: [String: Int]])?["accent"] else {
        return XCTFail("Expected converted accent color")
      }

      XCTAssertEqual(Set(accent.keys), ["R", "G", "B", "A"])
      XCTAssertTrue(accent.values.allSatisfy { (0...255).contains($0) })
    }

    waitForExpectations(timeout: 1)
  }

  func testSystemColorNotificationsStopAfterCancellation() {
    let plugin = SystemThemePlugin()
    var events: [Any?] = []

    XCTAssertNil(plugin.onListen(withArguments: nil) { events.append($0) })
    NotificationCenter.default.post(name: systemColorsDidChange, object: nil)
    XCTAssertEqual(events.count, 1)

    XCTAssertNil(plugin.onCancel(withArguments: nil))
    NotificationCenter.default.post(name: systemColorsDidChange, object: nil)
    XCTAssertEqual(events.count, 1)
  }

  func testUnknownMethodUsesFlutterFallback() {
    let expectation = expectation(description: "not implemented result")

    SystemThemePlugin().handle(FlutterMethodCall(methodName: "unknown", arguments: nil)) { result in
      XCTAssertTrue((result as AnyObject?) === FlutterMethodNotImplemented)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }
}
