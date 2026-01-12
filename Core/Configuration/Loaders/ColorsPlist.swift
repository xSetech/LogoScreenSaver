// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit

/// Loads and parses color palette configuration from Colors.plist
public class ColorsPlist: PlistLoader {

    /// Parsed color configuration from Colors.plist
    public private(set) var config: ColorConfig = ColorConfig()

    /// Initialize by loading Colors.plist
    /// - Parameters:
    ///   - plist: The name of the plist file (without extension)
    ///   - bundle: The bundle containing the plist
    /// - Throws: ConfigurationError if the plist cannot be read or parsed
    public required init(named plist: String, from bundle: Bundle) throws {
        let plistData = try Self.readPlist(named: plist, from: bundle)
        try parse(config: plistData)
    }

    /// Parse the Colors.plist configuration
    public func parse(config plistData: [String: Any]) throws {
        let palettes = try Self.parseColorPalettes(from: plistData)
        let defaultPalette = Self.parseDefaultPalette(from: plistData)
        self.config = ColorConfig(palettes: palettes, defaultPalette: defaultPalette)
    }

    /// Helper to convert Any value to CGFloat
    private static func convertToCGFloat(_ value: Any) throws -> CGFloat {
        if let v = value as? CGFloat {
            return v
        } else if let v = value as? Double {
            return CGFloat(v)
        } else if let v = value as? Int {
            return CGFloat(v)
        } else {
            throw ConfigurationError.configFileReadFailed(reason: "Invalid color component type: \(type(of: value))")
        }
    }

    /// Parse color palettes from configuration
    public static func parseColorPalettes(from config: [String: Any]) throws -> [String: ColorPalette] {
        guard let palettesDict = config["Color Palettes"] as? [String: [[String: Any]]] else {
            throw ConfigurationError.noColorPalettesFound
        }

        var palettes: [String: ColorPalette] = [:]

        for (paletteName, colorsArray) in palettesDict {
            let palette = try parseSinglePalette(name: paletteName, colorsArray: colorsArray)
            palettes[paletteName] = palette
        }

        guard !palettes.isEmpty else {
            throw ConfigurationError.noColorPalettesFound
        }

        return palettes
    }

    /// Parse default palette name from configuration
    public static func parseDefaultPalette(from config: [String: Any]) -> String? {
        let paletteName = config["Color Palette"] as? String ?? "Spectrum"

        // Handle "None" as nil
        if paletteName == "None" {
            return nil
        }

        return paletteName
    }

    // MARK: - Private Parsing Helpers

    /// Parse a single palette from its colors array
    private static func parseSinglePalette(name: String, colorsArray: [[String: Any]]) throws -> ColorPalette {
        guard !colorsArray.isEmpty else {
            throw ConfigurationError.invalidColorPalette(name: name, reason: "Palette has no valid colors")
        }

        var colorRanges: [ColorRange] = []

        for colorDict in colorsArray {
            let colorRange = try parseColorRange(paletteName: name, dict: colorDict)
            colorRanges.append(colorRange)
        }

        return CollisionColorPalette(name: name, colorRanges: colorRanges)
    }

    /// Parse a single color range from a color dictionary
    private static func parseColorRange(paletteName: String, dict: [String: Any]) throws -> ColorRange {
        guard let colorSpace = dict["Color Space"] as? String else {
            throw ConfigurationError.invalidColorPalette(name: paletteName, reason: "Missing 'Color Space' key")
        }

        switch colorSpace {
        case "RGB":
            return try parseRGBColorRange(paletteName: paletteName, dict: dict)
        case "HSV":
            return try parseHSVColorRange(paletteName: paletteName, dict: dict)
        default:
            throw ConfigurationError.invalidColorPalette(name: paletteName, reason: "Invalid color space '\(colorSpace)'")
        }
    }

    /// Parse RGB color range
    private static func parseRGBColorRange(paletteName: String, dict: [String: Any]) throws -> ColorRange {
        let redRange = try parseRangeOrValue(from: dict, key: "Red", paletteName: paletteName)
        let greenRange = try parseRangeOrValue(from: dict, key: "Green", paletteName: paletteName)
        let blueRange = try parseRangeOrValue(from: dict, key: "Blue", paletteName: paletteName)
        let alphaRange = try parseRangeOrValue(from: dict, key: "Alpha", paletteName: paletteName, defaultValue: 1.0)

        // Validate RGB values are in [0, 1]
        guard (0...1).contains(redRange.lowerBound) && (0...1).contains(redRange.upperBound) &&
              (0...1).contains(greenRange.lowerBound) && (0...1).contains(greenRange.upperBound) &&
              (0...1).contains(blueRange.lowerBound) && (0...1).contains(blueRange.upperBound) &&
              (0...1).contains(alphaRange.lowerBound) && (0...1).contains(alphaRange.upperBound) else {
            throw ConfigurationError.invalidColorPalette(name: paletteName, reason: "RGB/Alpha values out of range [0,1]")
        }

        return RGBColorRange(red: redRange, green: greenRange, blue: blueRange, alpha: alphaRange)
    }

    /// Parse HSV color range
    private static func parseHSVColorRange(paletteName: String, dict: [String: Any]) throws -> ColorRange {
        let hueRange = try parseRangeOrValue(from: dict, key: "Hue", paletteName: paletteName)
        let saturationRange = try parseRangeOrValue(from: dict, key: "Saturation", paletteName: paletteName)
        let valueRange = try parseRangeOrValue(from: dict, key: "Value", paletteName: paletteName)
        let alphaRange = try parseRangeOrValue(from: dict, key: "Alpha", paletteName: paletteName, defaultValue: 1.0)

        // Validate hue in [0, 360] and others in [0, 1]
        guard (0...360).contains(hueRange.lowerBound) && (0...360).contains(hueRange.upperBound) else {
            throw ConfigurationError.invalidColorPalette(name: paletteName, reason: "Hue out of range [0,360]")
        }

        guard (0...1).contains(saturationRange.lowerBound) && (0...1).contains(saturationRange.upperBound) &&
              (0...1).contains(valueRange.lowerBound) && (0...1).contains(valueRange.upperBound) &&
              (0...1).contains(alphaRange.lowerBound) && (0...1).contains(alphaRange.upperBound) else {
            throw ConfigurationError.invalidColorPalette(name: paletteName, reason: "Saturation/Value/Alpha out of range [0,1]")
        }

        return HSVColorRange(hue: hueRange, saturation: saturationRange, value: valueRange, alpha: alphaRange)
    }

    /// Parse a value that can be either a discrete number or a range string
    private static func parseRangeOrValue(
        from dict: [String: Any],
        key: String,
        paletteName: String,
        defaultValue: CGFloat? = nil
    ) throws -> ClosedRange<CGFloat> {
        if let stringValue = dict[key] as? String {
            // Parse range: "0.13...0.87"
            let parts = stringValue.components(separatedBy: "...")
            guard parts.count == 2 else {
                throw ConfigurationError.invalidColorPalette(name: paletteName, reason: "Invalid range format for \(key): '\(stringValue)'")
            }

            guard let lowerBoundDouble = Double(parts[0].trimmingCharacters(in: .whitespaces)),
                  let upperBoundDouble = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
                throw ConfigurationError.invalidColorPalette(name: paletteName, reason: "Invalid range values for \(key): '\(stringValue)'")
            }

            let lowerBound = CGFloat(lowerBoundDouble)
            let upperBound = CGFloat(upperBoundDouble)

            guard lowerBound <= upperBound else {
                throw ConfigurationError.invalidColorPalette(name: paletteName, reason: "Range lower bound > upper bound for \(key)")
            }

            return lowerBound...upperBound
        } else if let value = dict[key] {
            // Discrete value
            let cgValue = try convertToCGFloat(value)
            return cgValue...cgValue
        } else if let defaultValue = defaultValue {
            // Use default if provided
            return defaultValue...defaultValue
        } else {
            throw ConfigurationError.invalidColorPalette(name: paletteName, reason: "Missing \(key)")
        }
    }
}
