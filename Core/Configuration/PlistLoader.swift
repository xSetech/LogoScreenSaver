// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Protocol for loading and parsing plist configuration files
public protocol PlistLoader {
    /// Initialize by loading and parsing a plist file
    /// - Parameters:
    ///   - plist: The name of the plist file (without extension)
    ///   - bundle: The bundle containing the plist
    /// - Throws: ConfigurationError if the plist cannot be read or parsed
    init(named plist: String, from bundle: Bundle) throws

    /// Parse the configuration dictionary and populate the instance properties
    /// - Parameter config: The configuration dictionary loaded from the plist
    /// - Throws: ConfigurationError if parsing fails
    func parse(config: [String: Any]) throws
}

extension PlistLoader {
    /// Read a plist from the Config directory
    /// - Parameters:
    ///   - name: The name of the plist file (without extension)
    ///   - bundle: The bundle containing the plist
    /// - Returns: Dictionary containing the plist data
    /// - Throws: ConfigurationError if the plist cannot be read
    static func readPlist(named name: String, from bundle: Bundle) throws -> [String: Any] {
        // Try Config/ subdirectory first (SPM builds), then root Resources (Xcode builds)
        let configPath = bundle.path(forResource: name, ofType: "plist", inDirectory: "Config")
            ?? bundle.path(forResource: name, ofType: "plist")

        guard let configPath else {
            throw ConfigurationError.configFileNotFound(bundlePath: bundle.bundlePath)
        }

        let configURL = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: configURL)
        let config = try PropertyListSerialization.propertyList(from: data, format: nil)

        guard let configDict = config as? [String: Any] else {
            throw ConfigurationError.configFileReadFailed(reason: "\(name).plist is not a dictionary")
        }

        return configDict
    }
}
