import Flutter
import UIKit
import SwiftUI
import XCTest
@testable import system_theme

class RunnerTests: XCTestCase {

  @available(iOS 14.0, *)
  func testColorConversionRoundsRGBAChannels() {
    XCTAssertEqual(
      Color(UIColor(red: 1, green: 0, blue: 0.5, alpha: 0.5)).toHex(),
      ["R": 255, "G": 0, "B": 128, "A": 128]
    )
  }

  @available(iOS 14.0, *)
  func testColorConversionFallsBackToGrayscaleComponents() {
    XCTAssertEqual(
      Color(UIColor(white: 0.5, alpha: 1)).toHex(),
      ["R": 128, "G": 128, "B": 128, "A": 255]
    )
  }

  @available(iOS 14.0, *)
  func testWideGamutColorConversionProducesByteChannels() {
    let channels = Color(UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)).toHex()

    guard let channels else {
      return XCTFail("Expected wide-gamut color conversion to succeed")
    }

    XCTAssertTrue(channels.values.allSatisfy { (0...255).contains($0) })
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
