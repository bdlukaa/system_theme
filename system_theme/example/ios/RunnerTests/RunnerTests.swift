import Flutter
import UIKit
import SwiftUI
import XCTest
@testable import system_theme

class RunnerTests: XCTestCase {

  @available(iOS 14.0, *)
  func testColorConversion() {
    XCTAssertEqual(Color(UIColor(red: 1, green: 0, blue: 0.5, alpha: 0.5)).toHex(),
                   ["R": 255, "G": 0, "B": 128, "A": 128])
    XCTAssertEqual(Color(UIColor(white: 0.5, alpha: 1)).toHex(),
                   ["R": 128, "G": 128, "B": 128, "A": 255])
    let wideGamut = Color(UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)).toHex()
    XCTAssertNotNil(wideGamut)
    if let wideGamut = wideGamut {
      for channel in wideGamut.values {
        XCTAssertTrue((0...255).contains(channel))
      }
    }
  }

  @available(iOS 14.0, *)
  func testDefaultApplicationAccent() {
    let expected = Color.accentColor.toHex()
    XCTAssertNotNil(expected)
    SystemThemePlugin().handle(FlutterMethodCall(methodName: "SystemTheme.accentColor", arguments: nil)) { value in
      let result = value as? [String: [String: Int]]
      XCTAssertEqual(result?["accent"], expected)
    }
  }

  @available(iOS 14.0, *)
  func testUnconvertibleColor() {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
    let color = Color(UIColor(patternImage: image))
    XCTAssertNil(color.toHex())
  }

}
