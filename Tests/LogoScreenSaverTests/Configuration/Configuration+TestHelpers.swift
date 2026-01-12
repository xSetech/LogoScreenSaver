// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit
@testable import LogoScreenSaverCore

/// Test helpers for Configuration parsing
extension Configuration {

    /// Test helper: Parse color palettes from a configuration dictionary
    /// - Parameter config: Configuration dictionary
    /// - Returns: Dictionary mapping palette names to arrays of colors
    /// - Throws: ConfigurationError if parsing fails
    public func readColorPalettesFromConfig(config: [String: Any]) throws -> [String: ColorPalette] {
        return try ColorsPlist.parseColorPalettes(from: config)
    }

    /// Test helper: Parse logo entries from a configuration dictionary
    /// - Parameter config: Configuration dictionary
    /// - Returns: Array of logo configuration entries
    /// - Throws: ConfigurationError if parsing fails
    public func readLogosFromConfig(config: [String: Any]) throws -> [LogoConfigEntry] {
        return try LogosPlist.parseLogoEntries(from: config, bundle: bundle)
    }
}
