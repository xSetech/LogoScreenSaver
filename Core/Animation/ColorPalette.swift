// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit

// MARK: - ColorRange Protocol

/// Protocol for individual color definitions within a palette.
/// Each element in a palette's "Colors" array becomes a ColorRange.
public protocol ColorRange {
    /// Generate a random color from this color range
    func randomColor() -> NSColor
}

// MARK: - RGB Color Range

/// Handles RGB colors with discrete values or ranges
public final class RGBColorRange: ColorRange {
    private let redRange: ClosedRange<CGFloat>
    private let greenRange: ClosedRange<CGFloat>
    private let blueRange: ClosedRange<CGFloat>
    private let alphaRange: ClosedRange<CGFloat>
    private let isRange: Bool  // True if any component is a range

    public init(
        red: ClosedRange<CGFloat>,
        green: ClosedRange<CGFloat>,
        blue: ClosedRange<CGFloat>,
        alpha: ClosedRange<CGFloat> = 1.0...1.0
    ) {
        self.redRange = red
        self.greenRange = green
        self.blueRange = blue
        self.alphaRange = alpha

        // Check if any component is a range (not a single value)
        self.isRange = red.lowerBound != red.upperBound ||
                       green.lowerBound != green.upperBound ||
                       blue.lowerBound != blue.upperBound ||
                       alpha.lowerBound != alpha.upperBound
    }

    public func randomColor() -> NSColor {
        let red = generateValue(in: redRange)
        let green = generateValue(in: greenRange)
        let blue = generateValue(in: blueRange)
        let alpha = generateValue(in: alphaRange)

        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private func generateValue(in range: ClosedRange<CGFloat>) -> CGFloat {
        // If it's a single value, return it
        if range.lowerBound == range.upperBound {
            return range.lowerBound
        }

        // Generate random value in range
        let value = CGFloat.random(in: range)

        // Apply quantization if this is a range (for Spectrum-like behavior)
        if isRange {
            return quantize(value, toDecimalPlaces: 2)
        }

        return value
    }

    /// Quantize value to specified decimal places
    private func quantize(_ value: CGFloat, toDecimalPlaces places: Int) -> CGFloat {
        let scale = pow(10.0, CGFloat(places))
        return round(value * scale) / scale
    }
}

// MARK: - HSV Color Range

/// Handles HSV colors with discrete values or ranges
public final class HSVColorRange: ColorRange {
    private let hueRange: ClosedRange<CGFloat>         // 0-360 degrees
    private let saturationRange: ClosedRange<CGFloat>  // 0.0-1.0
    private let valueRange: ClosedRange<CGFloat>       // 0.0-1.0 (brightness)
    private let alphaRange: ClosedRange<CGFloat>       // 0.0-1.0

    public init(
        hue: ClosedRange<CGFloat>,
        saturation: ClosedRange<CGFloat>,
        value: ClosedRange<CGFloat>,
        alpha: ClosedRange<CGFloat> = 1.0...1.0
    ) {
        self.hueRange = hue
        self.saturationRange = saturation
        self.valueRange = value
        self.alphaRange = alpha
    }

    public func randomColor() -> NSColor {
        let hue = generateValue(in: hueRange)
        let saturation = generateValue(in: saturationRange)
        let value = generateValue(in: valueRange)
        let alpha = generateValue(in: alphaRange)

        // Convert hue from degrees (0-360) to NSColor's expected range (0.0-1.0)
        let normalizedHue = hue / 360.0

        return NSColor(
            hue: normalizedHue,
            saturation: saturation,
            brightness: value,
            alpha: alpha
        )
    }

    private func generateValue(in range: ClosedRange<CGFloat>) -> CGFloat {
        // If it's a single value, return it
        if range.lowerBound == range.upperBound {
            return range.lowerBound
        }

        // Generate random value in range
        return CGFloat.random(in: range)
    }
}

// MARK: - ColorPalette Protocol

/// Protocol defining color palette behavior for logo coloring
public protocol ColorPalette {
    /// The palette name/identifier
    var name: String { get }

    /// The currently selected color
    var currentColor: NSColor { get }

    /// Called at each animation step - returns current color unchanged
    func onStep() -> NSColor

    /// Called on collision - advances to next color and returns it
    func onCollision() -> NSColor
}

// MARK: - Collision Color Palette

/// Color palette that changes color on collisions
/// This is the standard palette behavior matching the existing implementation
public final class CollisionColorPalette: ColorPalette {
    public let name: String
    public private(set) var currentColor: NSColor

    private let colorRanges: [ColorRange]
    private var currentIndex: Int

    public init(name: String, colorRanges: [ColorRange]) {
        self.name = name
        self.colorRanges = colorRanges
        self.currentIndex = 0

        // Initialize with the first color
        self.currentColor = colorRanges.first?.randomColor() ?? .white
    }

    public func onStep() -> NSColor {
        // Return current color unchanged
        return currentColor
    }

    public func onCollision() -> NSColor {
        // Advance to next color range (with wraparound)
        let colorRange = nextColorRange()

        // Generate new color from the range
        let newColor = nextColorInRange(from: colorRange)

        // Update current color
        currentColor = newColor

        return currentColor
    }

    // MARK: - Internal Methods

    /// Selects next ColorRange from Colors array (with wraparound)
    private func nextColorRange() -> ColorRange {
        currentIndex = (currentIndex + 1) % colorRanges.count
        return colorRanges[currentIndex]
    }

    /// Generates color from the given ColorRange
    private func nextColorInRange(from colorRange: ColorRange) -> NSColor {
        return colorRange.randomColor()
    }
}
