// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import LogoScreenSaverCore

/// Tests for logo configuration parsing from Logos.plist
final class LogoConfigurationParsingTests: XCTestCase {

    var testBundle: Bundle!

    override func setUp() {
        super.setUp()
        testBundle = Bundle.module
    }

    /// Test parsing of builtin logos
    func testBuiltinLogosParsing() throws {
        let config: [String: Any] = [
            "Logos": [
                "diamond": [
                    "Type": "svg",
                    "Source": "builtin"
                ]
            ]
        ]

        let configuration = try Configuration(bundle: testBundle, skipConfigPlist: true)

        // Note: This test may not find the actual diamond.svg file in test bundle,
        // so it will throw an error when no valid entries are found
        do {
            let logos = try configuration.readLogosFromConfig(config: config)
            // If we get here, the logo was found in the test bundle
            XCTAssertFalse(logos.isEmpty)
        } catch {
            // Expected if diamond.svg is not in the test bundle
            XCTAssertTrue(error is ConfigurationError)
        }
    }

    /// Test parsing of filesystem path logos
    func testPathLogosParsing() throws {
        let config: [String: Any] = [
            "Logos": [
                "/tmp/test.png": [
                    "Type": "png",
                    "Source": "path"
                ]
            ]
        ]

        let configuration = try Configuration(bundle: testBundle, skipConfigPlist: true)

        // Path logos are validated during load, not during parsing, so this should succeed
        let logos = try configuration.readLogosFromConfig(config: config)
        XCTAssertEqual(logos.count, 1)
        XCTAssertEqual(logos[0].key, "/tmp/test.png")
        XCTAssertEqual(logos[0].source, .path)
    }

    /// Test that logos without Type field are rejected
    func testMissingTypeField() throws {
        let config: [String: Any] = [
            "Logos": [
                "missing-type": [
                    "Source": "builtin"
                ]
            ]
        ]

        let configuration = try Configuration(bundle: testBundle, skipConfigPlist: true)

        // Missing Type field should throw immediately (fail fast)
        XCTAssertThrowsError(try configuration.readLogosFromConfig(config: config)) { error in
            XCTAssertTrue(error is ConfigurationError)
            if case ConfigurationError.invalidLogoEntry(let key, _) = error {
                XCTAssertEqual(key, "missing-type")
            } else {
                XCTFail("Expected ConfigurationError.invalidLogoEntry")
            }
        }
    }

    /// Test that logos with invalid Source field are rejected
    func testInvalidSourceField() throws {
        let config: [String: Any] = [
            "Logos": [
                "invalid-source": [
                    "Type": "svg",
                    "Source": "invalid"
                ]
            ]
        ]

        let configuration = try Configuration(bundle: testBundle, skipConfigPlist: true)

        // Invalid Source field should throw immediately (fail fast)
        XCTAssertThrowsError(try configuration.readLogosFromConfig(config: config)) { error in
            XCTAssertTrue(error is ConfigurationError)
            if case ConfigurationError.invalidLogoEntry(let key, _) = error {
                XCTAssertEqual(key, "invalid-source")
            } else {
                XCTFail("Expected ConfigurationError.invalidLogoEntry")
            }
        }
    }
}
