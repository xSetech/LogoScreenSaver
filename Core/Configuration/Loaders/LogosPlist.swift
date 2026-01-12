// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit

/// Loads and parses logo configuration from Logos.plist
public class LogosPlist: PlistLoader {

    /// Parsed logo configuration from Logos.plist
    public private(set) var config: LogoConfig = LogoConfig()

    /// Bundle reference needed for parsing logo entries
    private let bundle: Bundle

    /// Initialize by loading Logos.plist
    /// - Parameters:
    ///   - plist: The name of the plist file (without extension)
    ///   - bundle: The bundle containing the plist
    /// - Throws: ConfigurationError if the plist cannot be read or parsed
    public required init(named plist: String, from bundle: Bundle) throws {
        self.bundle = bundle
        let plistData = try Self.readPlist(named: plist, from: bundle)
        try parse(config: plistData)
    }

    /// Parse the Logos.plist configuration
    public func parse(config plistData: [String: Any]) throws {
        let entries = try Self.parseLogoEntries(from: plistData, bundle: bundle)
        self.config = LogoConfig(entries: entries)
    }

    /// Parse logo entries from configuration
    public static func parseLogoEntries(from config: [String: Any], bundle: Bundle) throws -> [LogoConfigEntry] {
        guard let logosDict = config["Logos"] as? [String: [String: Any]] else {
            throw ConfigurationError.noValidLogoEntriesFound
        }

        var entries: [LogoConfigEntry] = []

        for (key, value) in logosDict {
            guard let type = value["Type"] as? String else {
                throw ConfigurationError.invalidLogoEntry(key: key, reason: "Missing Type field")
            }

            guard let sourceString = value["Source"] as? String,
                  let source = LogoSource(rawValue: sourceString) else {
                throw ConfigurationError.invalidLogoEntry(key: key, reason: "Missing or invalid Source field")
            }

            let path: URL

            switch source {
            case .builtin:
                // Look for the logo in the bundle's Logos/ directory
                guard let bundlePath = bundle.path(forResource: key, ofType: type, inDirectory: "Logos") else {
                    throw ConfigurationError.invalidLogoEntry(key: key, reason: "Builtin logo file not found: \(key).\(type)")
                }
                path = URL(fileURLWithPath: bundlePath)

            case .path:
                // Use the key as the absolute path
                path = URL(fileURLWithPath: key)
            }

            entries.append(LogoConfigEntry(
                key: key,
                path: path,
                source: source
            ))
        }

        guard !entries.isEmpty else {
            throw ConfigurationError.noValidLogoEntriesFound
        }

        return entries
    }

}
