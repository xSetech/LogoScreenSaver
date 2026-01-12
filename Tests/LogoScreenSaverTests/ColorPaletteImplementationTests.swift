// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import LogoScreenSaverCore

final class ColorPaletteImplementationTests: XCTestCase {

    // MARK: - RGB Color Range Tests

    func testRGBColorRangeDiscrete() throws {
        // Test discrete RGB color (single values, not ranges)
        let colorRange = RGBColorRange(
            red: 0.8...0.8,
            green: 0.2...0.2,
            blue: 0.5...0.5,
            alpha: 1.0...1.0
        )

        // Generate multiple colors - all should be identical
        for _ in 0..<10 {
            let color = colorRange.randomColor()
            let rgb = color.usingColorSpace(.deviceRGB)!

            XCTAssertEqual(rgb.redComponent, 0.8, accuracy: 0.001)
            XCTAssertEqual(rgb.greenComponent, 0.2, accuracy: 0.001)
            XCTAssertEqual(rgb.blueComponent, 0.5, accuracy: 0.001)
            XCTAssertEqual(rgb.alphaComponent, 1.0, accuracy: 0.001)
        }
    }

    func testRGBColorRangeWithRanges() throws {
        // Test RGB range (Spectrum-like behavior)
        let colorRange = RGBColorRange(
            red: 0.13...0.87,
            green: 0.13...0.87,
            blue: 0.13...0.87,
            alpha: 1.0...1.0
        )

        // Generate multiple colors and verify they're within range
        for _ in 0..<100 {
            let color = colorRange.randomColor()
            let rgb = color.usingColorSpace(.deviceRGB)!

            // Verify values are within range
            XCTAssertGreaterThanOrEqual(rgb.redComponent, 0.13)
            XCTAssertLessThanOrEqual(rgb.redComponent, 0.87)
            XCTAssertGreaterThanOrEqual(rgb.greenComponent, 0.13)
            XCTAssertLessThanOrEqual(rgb.greenComponent, 0.87)
            XCTAssertGreaterThanOrEqual(rgb.blueComponent, 0.13)
            XCTAssertLessThanOrEqual(rgb.blueComponent, 0.87)
            XCTAssertEqual(rgb.alphaComponent, 1.0, accuracy: 0.001)

            // Verify quantization to 2 decimal places
            let redQuantized = round(rgb.redComponent * 100) / 100
            let greenQuantized = round(rgb.greenComponent * 100) / 100
            let blueQuantized = round(rgb.blueComponent * 100) / 100

            XCTAssertEqual(rgb.redComponent, redQuantized, accuracy: 0.001)
            XCTAssertEqual(rgb.greenComponent, greenQuantized, accuracy: 0.001)
            XCTAssertEqual(rgb.blueComponent, blueQuantized, accuracy: 0.001)
        }
    }

    func testRGBColorRangePartialRanges() throws {
        // Test mix of discrete and range values
        let colorRange = RGBColorRange(
            red: 0.5...0.5,      // Discrete
            green: 0.2...0.8,    // Range
            blue: 1.0...1.0,     // Discrete
            alpha: 1.0...1.0
        )

        for _ in 0..<50 {
            let color = colorRange.randomColor()
            let rgb = color.usingColorSpace(.deviceRGB)!

            // Red should always be 0.5
            XCTAssertEqual(rgb.redComponent, 0.5, accuracy: 0.001)

            // Green should vary in range 0.2-0.8
            XCTAssertGreaterThanOrEqual(rgb.greenComponent, 0.2)
            XCTAssertLessThanOrEqual(rgb.greenComponent, 0.8)

            // Blue should always be 1.0
            XCTAssertEqual(rgb.blueComponent, 1.0, accuracy: 0.001)
        }
    }

    // MARK: - HSV Color Range Tests

    func testHSVColorRangeDiscrete() throws {
        // Test discrete HSV color
        let colorRange = HSVColorRange(
            hue: 0...0,          // Red (0 degrees)
            saturation: 1.0...1.0,
            value: 1.0...1.0,
            alpha: 1.0...1.0
        )

        // Generate multiple colors - all should be pure red
        for _ in 0..<10 {
            let color = colorRange.randomColor()
            let hsv = color.usingColorSpace(.deviceRGB)!

            // Hue should be 0 or 360 (both are red due to wraparound)
            let hue = hsv.hueComponent * 360
            let isRed = (hue < 1.0) || (hue > 359.0)
            XCTAssertTrue(isRed, "Hue \(hue) should be close to 0 or 360 (red)")

            XCTAssertEqual(hsv.saturationComponent, 1.0, accuracy: 0.001)
            XCTAssertEqual(hsv.brightnessComponent, 1.0, accuracy: 0.001)
            XCTAssertEqual(hsv.alphaComponent, 1.0, accuracy: 0.001)
        }
    }

    func testHSVColorRangeWithRanges() throws {
        // Test HSV ranges (pastel-like behavior)
        let colorRange = HSVColorRange(
            hue: 0...360,
            saturation: 0.2...0.4,
            value: 0.8...1.0,
            alpha: 1.0...1.0
        )

        for _ in 0..<100 {
            let color = colorRange.randomColor()
            let hsv = color.usingColorSpace(.deviceRGB)!

            // Hue can be anything (0-360)
            let hue = hsv.hueComponent * 360
            XCTAssertGreaterThanOrEqual(hue, 0)
            XCTAssertLessThanOrEqual(hue, 360)

            // Saturation should be low (pastel)
            XCTAssertGreaterThanOrEqual(hsv.saturationComponent, 0.2)
            XCTAssertLessThanOrEqual(hsv.saturationComponent, 0.4)

            // Value should be high (bright)
            XCTAssertGreaterThanOrEqual(hsv.brightnessComponent, 0.8)
            XCTAssertLessThanOrEqual(hsv.brightnessComponent, 1.0)

            XCTAssertEqual(hsv.alphaComponent, 1.0, accuracy: 0.001)
        }
    }

    func testHSVColorRangeSpecificHue() throws {
        // Test HSV with specific hue range (e.g., only greens)
        let colorRange = HSVColorRange(
            hue: 100...140,  // Green range
            saturation: 0.8...1.0,
            value: 0.6...0.9,
            alpha: 1.0...1.0
        )

        for _ in 0..<50 {
            let color = colorRange.randomColor()
            let hsv = color.usingColorSpace(.deviceRGB)!

            // Hue should be in green range
            let hue = hsv.hueComponent * 360
            XCTAssertGreaterThanOrEqual(hue, 100)
            XCTAssertLessThanOrEqual(hue, 140)

            XCTAssertGreaterThanOrEqual(hsv.saturationComponent, 0.8)
            XCTAssertLessThanOrEqual(hsv.saturationComponent, 1.0)

            XCTAssertGreaterThanOrEqual(hsv.brightnessComponent, 0.6)
            XCTAssertLessThanOrEqual(hsv.brightnessComponent, 0.9)
        }
    }

    // MARK: - CollisionColorPalette Tests

    func testCollisionColorPaletteOnStep() throws {
        // Create a palette with multiple color ranges
        let colorRanges: [ColorRange] = [
            RGBColorRange(red: 1.0...1.0, green: 0.0...0.0, blue: 0.0...0.0),  // Red
            RGBColorRange(red: 0.0...0.0, green: 1.0...1.0, blue: 0.0...0.0),  // Green
            RGBColorRange(red: 0.0...0.0, green: 0.0...0.0, blue: 1.0...1.0)   // Blue
        ]

        let palette = CollisionColorPalette(name: "Test", colorRanges: colorRanges)

        // onStep should return the same color multiple times
        let color1 = palette.onStep()
        let color2 = palette.onStep()
        let color3 = palette.onStep()

        XCTAssertTrue(areColorsEqual(color1, color2))
        XCTAssertTrue(areColorsEqual(color2, color3))
    }

    func testCollisionColorPaletteOnCollision() throws {
        // Create a palette with discrete colors
        let colorRanges: [ColorRange] = [
            RGBColorRange(red: 1.0...1.0, green: 0.0...0.0, blue: 0.0...0.0),  // Red
            RGBColorRange(red: 0.0...0.0, green: 1.0...1.0, blue: 0.0...0.0),  // Green
            RGBColorRange(red: 0.0...0.0, green: 0.0...0.0, blue: 1.0...1.0)   // Blue
        ]

        let palette = CollisionColorPalette(name: "Test", colorRanges: colorRanges)

        // Initial color should be first color (red)
        let initialColor = palette.currentColor
        let rgb0 = initialColor.usingColorSpace(.deviceRGB)!
        XCTAssertEqual(rgb0.redComponent, 1.0, accuracy: 0.001)

        // First collision should give us second color (green)
        let color1 = palette.onCollision()
        let rgb1 = color1.usingColorSpace(.deviceRGB)!
        XCTAssertEqual(rgb1.greenComponent, 1.0, accuracy: 0.001)

        // Second collision should give us third color (blue)
        let color2 = palette.onCollision()
        let rgb2 = color2.usingColorSpace(.deviceRGB)!
        XCTAssertEqual(rgb2.blueComponent, 1.0, accuracy: 0.001)

        // Third collision should wrap around to first color (red)
        let color3 = palette.onCollision()
        let rgb3 = color3.usingColorSpace(.deviceRGB)!
        XCTAssertEqual(rgb3.redComponent, 1.0, accuracy: 0.001)
    }

    func testCollisionColorPaletteCurrentColor() throws {
        // Test that currentColor property stays in sync with onCollision()
        let colorRanges: [ColorRange] = [
            RGBColorRange(red: 1.0...1.0, green: 0.0...0.0, blue: 0.0...0.0),
            RGBColorRange(red: 0.0...0.0, green: 1.0...1.0, blue: 0.0...0.0)
        ]

        let palette = CollisionColorPalette(name: "Test", colorRanges: colorRanges)

        // After collision, currentColor should match returned color
        let collisionColor = palette.onCollision()
        XCTAssertTrue(areColorsEqual(collisionColor, palette.currentColor))

        // onStep should return the current color
        let stepColor = palette.onStep()
        XCTAssertTrue(areColorsEqual(stepColor, palette.currentColor))
    }

    func testCollisionColorPaletteName() throws {
        let colorRanges: [ColorRange] = [
            RGBColorRange(red: 1.0...1.0, green: 0.0...0.0, blue: 0.0...0.0)
        ]

        let palette = CollisionColorPalette(name: "Spectrum", colorRanges: colorRanges)

        XCTAssertEqual(palette.name, "Spectrum")
    }

    // MARK: - Helper Methods

    private func areColorsEqual(_ c1: NSColor, _ c2: NSColor) -> Bool {
        guard let rgb1 = c1.usingColorSpace(.deviceRGB),
              let rgb2 = c2.usingColorSpace(.deviceRGB) else {
            return false
        }

        return abs(rgb1.redComponent - rgb2.redComponent) < 0.001 &&
               abs(rgb1.greenComponent - rgb2.greenComponent) < 0.001 &&
               abs(rgb1.blueComponent - rgb2.blueComponent) < 0.001 &&
               abs(rgb1.alphaComponent - rgb2.alphaComponent) < 0.001
    }
}
