// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import LogoScreenSaverCore

/// Integration tests for full configuration loading flow
final class ConfigurationIntegrationTests: XCTestCase {

    var testBundle: Bundle!

    override func setUp() {
        super.setUp()
        testBundle = Bundle.module
    }

    /// Test default configuration (no plist)
    func testDefaultConfiguration() throws {
        let configuration = try Configuration(bundle: testBundle, skipConfigPlist: true)

        XCTAssertFalse(configuration.debugConfig.debugMode)
        XCTAssertEqual(configuration.colorConfig.defaultPalette, "Spectrum")
    }

    /// Test parsing color configuration from dictionary
    func testColorConfigurationParsing() throws {
        let testColor: [String: Any] = [
            "Color Space": "RGB",
            "Red": 0.5,
            "Green": 0.5,
            "Blue": 0.5,
            "Alpha": 1.0
        ]
        let config: [String: Any] = [
            "Color Palettes": [
                "TestPalette": [testColor]
            ],
            "Color Palette": "TestPalette"
        ]

        let palettes = try ColorsPlist.parseColorPalettes(from: config)
        let defaultPalette = ColorsPlist.parseDefaultPalette(from: config)

        XCTAssertEqual(defaultPalette, "TestPalette")
        XCTAssertNotNil(palettes["TestPalette"])
        XCTAssertEqual(palettes["TestPalette"]?.name, "TestPalette")
    }

    /// Test debug configuration parsing from dictionary
    func testDebugConfigurationParsing() throws {
        let config: [String: Any] = [
            "Debug Mode": true,
            "Log Level": "D"
        ]

        let debugMode = DebugPlist.parseDebugMode(from: config)
        let logLevel = try DebugPlist.parseLogLevel(from: config)

        XCTAssertTrue(debugMode)
        XCTAssertEqual(logLevel, .debug)
    }

    /// Test Spectrum palette default fallback
    func testSpectrumPaletteDefault() throws {
        let config: [String: Any] = [:]

        let defaultPalette = ColorsPlist.parseDefaultPalette(from: config)

        XCTAssertEqual(defaultPalette, "Spectrum")
    }

    /// Test logo frame size limit parsing and validation
    func testLogoFrameSizeLimitParsing() throws {
        // Test valid limit (0.25 = 25%)
        let configWithLimit: [String: Any] = [
            "Debug Mode": false,
            "Log Level": "I",
            "Logo Frame Size Limit": 0.25
        ]

        let limit = DebugPlist.parseLogoFrameSizeLimit(from: configWithLimit)

        XCTAssertEqual(limit, 0.25)
        XCTAssertGreaterThan(limit, 0.0, "Logo frame size limit must be greater than 0%")
        XCTAssertLessThan(limit, 1.0, "Logo frame size limit must be less than 100%")
    }

    /// Test logo frame size limit defaults to 0.25 when missing
    func testLogoFrameSizeLimitDefault() throws {
        let configWithoutLimit: [String: Any] = [
            "Debug Mode": false,
            "Log Level": "I"
        ]

        let limit = DebugPlist.parseLogoFrameSizeLimit(from: configWithoutLimit)

        XCTAssertEqual(limit, 0.25, "Default logo frame size limit should be 0.25 (25%)")
        XCTAssertGreaterThan(limit, 0.0, "Logo frame size limit must be greater than 0%")
        XCTAssertLessThan(limit, 1.0, "Logo frame size limit must be less than 100%")
    }
}
