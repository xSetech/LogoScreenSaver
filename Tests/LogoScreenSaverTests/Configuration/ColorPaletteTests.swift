// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import LogoScreenSaverCore

/// Tests for color palette parsing and validation
final class ColorPaletteTests: XCTestCase {

    var testBundle: Bundle!

    override func setUp() {
        super.setUp()
        testBundle = Bundle.module
    }

    /// Test valid color palette parsing with proper RGBA values
    func testValidColorPaletteParsing() throws {
        let color1: [String: Any] = [
            "Color Space": "RGB",
            "Red": 0.5,
            "Green": 0.6,
            "Blue": 0.7,
            "Alpha": 1.0
        ]
        let color2: [String: Any] = [
            "Color Space": "RGB",
            "Red": 1.0,
            "Green": 0.0,
            "Blue": 0.5,
            "Alpha": 0.8
        ]
        let config: [String: Any] = [
            "Color Palettes": [
                "TestPalette": [color1, color2]
            ]
        ]

        let configuration = try Configuration(bundle: testBundle, skipConfigPlist: true)
        let palettes = try configuration.readColorPalettesFromConfig(config: config)

        XCTAssertEqual(palettes.count, 1)
        XCTAssertNotNil(palettes["TestPalette"])
        XCTAssertEqual(palettes["TestPalette"]?.name, "TestPalette")
    }

    /// Test that colors with values out of range [0,1] throw error (fail fast)
    func testInvalidColorValuesOutOfRange() throws {
        let config: [String: Any] = [
            "Color Palettes": [
                "InvalidPalette": [
                    [
                        "Color Space": "RGB",
                        "Red": 1.5,  // Out of range
                        "Green": 0.5,
                        "Blue": 0.5,
                        "Alpha": 1.0
                    ]
                ]
            ]
        ]

        let configuration = try Configuration(bundle: testBundle, skipConfigPlist: true)

        // Invalid color values should throw immediately (fail fast)
        XCTAssertThrowsError(try configuration.readColorPalettesFromConfig(config: config)) { error in
            XCTAssertTrue(error is ConfigurationError)
            if case ConfigurationError.invalidColorPalette(let name, _) = error {
                XCTAssertEqual(name, "InvalidPalette")
            } else {
                XCTFail("Expected ConfigurationError.invalidColorPalette")
            }
        }
    }

    /// Test handling of missing color components (R/G/B/A) throws error (fail fast)
    func testMissingColorComponents() throws {
        let config: [String: Any] = [
            "Color Palettes": [
                "MissingComponents": [
                    [
                        "Color Space": "RGB",
                        "Red": 0.5,
                        "Green": 0.5
                        // Missing Blue (Alpha is optional, defaults to 1.0)
                    ]
                ]
            ]
        ]

        let configuration = try Configuration(bundle: testBundle, skipConfigPlist: true)

        // Missing components should throw immediately (fail fast)
        XCTAssertThrowsError(try configuration.readColorPalettesFromConfig(config: config)) { error in
            XCTAssertTrue(error is ConfigurationError)
            if case ConfigurationError.invalidColorPalette(let name, _) = error {
                XCTAssertEqual(name, "MissingComponents")
            } else {
                XCTFail("Expected ConfigurationError.invalidColorPalette")
            }
        }
    }

    /// Test handling of empty palette (no valid colors) throws error (fail fast)
    func testEmptyPalette() throws {
        let config: [String: Any] = [
            "Color Palettes": [
                "EmptyPalette": []
            ]
        ]

        let configuration = try Configuration(bundle: testBundle, skipConfigPlist: true)

        // Empty palette should throw immediately (fail fast)
        XCTAssertThrowsError(try configuration.readColorPalettesFromConfig(config: config)) { error in
            XCTAssertTrue(error is ConfigurationError)
            if case ConfigurationError.invalidColorPalette(let name, _) = error {
                XCTAssertEqual(name, "EmptyPalette")
            } else {
                XCTFail("Expected ConfigurationError.invalidColorPalette")
            }
        }
    }

    /// Test that valid palette names (including Spectrum) are accepted
    func testValidPaletteNamesAccepted() throws {
        // Test with "Spectrum" (special palette)
        let spectrumConfig: [String: Any] = [
            "Color Palette": "Spectrum"
        ]

        let defaultPalette1 = ColorsPlist.parseDefaultPalette(from: spectrumConfig)
        XCTAssertEqual(defaultPalette1, "Spectrum")

        // Test with a defined palette
        let customConfig: [String: Any] = [
            "Color Palettes": [
                "CustomPalette": [
                    [
                        "Color Space": "RGB",
                        "Red": 0.5,
                        "Green": 0.5,
                        "Blue": 0.5,
                        "Alpha": 1.0
                    ]
                ]
            ],
            "Color Palette": "CustomPalette"
        ]

        let defaultPalette2 = ColorsPlist.parseDefaultPalette(from: customConfig)
        let palettes = try ColorsPlist.parseColorPalettes(from: customConfig)

        XCTAssertEqual(defaultPalette2, "CustomPalette")
        XCTAssertNotNil(palettes["CustomPalette"])
    }

    /// Test parsing RGB color range (like Spectrum)
    func testParseRGBColorRange() throws {
        let config: [String: Any] = [
            "Color Palettes": [
                "Spectrum": [
                    [
                        "Color Space": "RGB",
                        "Red": "0.13...0.87",
                        "Green": "0.13...0.87",
                        "Blue": "0.13...0.87",
                        "Alpha": 1.0
                    ]
                ]
            ]
        ]

        let palettes = try ColorsPlist.parseColorPalettes(from: config)

        XCTAssertEqual(palettes.count, 1)
        XCTAssertNotNil(palettes["Spectrum"])
        XCTAssertEqual(palettes["Spectrum"]?.name, "Spectrum")
    }

    /// Test parsing HSV color range
    func testParseHSVColorRange() throws {
        let config: [String: Any] = [
            "Color Palettes": [
                "Pastel": [
                    [
                        "Color Space": "HSV",
                        "Hue": "0...360",
                        "Saturation": "0.2...0.4",
                        "Value": "0.8...1.0",
                        "Alpha": 1.0
                    ]
                ]
            ]
        ]

        let palettes = try ColorsPlist.parseColorPalettes(from: config)

        XCTAssertEqual(palettes.count, 1)
        XCTAssertNotNil(palettes["Pastel"])
        XCTAssertEqual(palettes["Pastel"]?.name, "Pastel")
    }

    /// Test invalid range format throws error
    func testInvalidRangeFormat() throws {
        let config: [String: Any] = [
            "Color Palettes": [
                "InvalidRange": [
                    [
                        "Color Space": "RGB",
                        "Red": "0.13-0.87",  // Wrong separator
                        "Green": 0.5,
                        "Blue": 0.5,
                        "Alpha": 1.0
                    ]
                ]
            ]
        ]

        XCTAssertThrowsError(try ColorsPlist.parseColorPalettes(from: config)) { error in
            XCTAssertTrue(error is ConfigurationError)
            if case ConfigurationError.invalidColorPalette(let name, _) = error {
                XCTAssertEqual(name, "InvalidRange")
            } else {
                XCTFail("Expected ConfigurationError.invalidColorPalette")
            }
        }
    }

    /// Test invalid color space throws error
    func testInvalidColorSpace() throws {
        let config: [String: Any] = [
            "Color Palettes": [
                "InvalidSpace": [
                    [
                        "Color Space": "CMYK",  // Unsupported
                        "Red": 0.5,
                        "Green": 0.5,
                        "Blue": 0.5,
                        "Alpha": 1.0
                    ]
                ]
            ]
        ]

        XCTAssertThrowsError(try ColorsPlist.parseColorPalettes(from: config)) { error in
            XCTAssertTrue(error is ConfigurationError)
            if case ConfigurationError.invalidColorPalette(let name, _) = error {
                XCTAssertEqual(name, "InvalidSpace")
            } else {
                XCTFail("Expected ConfigurationError.invalidColorPalette")
            }
        }
    }
}
