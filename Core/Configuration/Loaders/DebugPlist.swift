// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Loads and parses debug configuration from Debug.plist
public class DebugPlist: PlistLoader {

    /// Parsed debug configuration from Debug.plist
    public private(set) var config: DebugConfig = DebugConfig()

    /// Initialize by loading Debug.plist
    /// - Parameters:
    ///   - plist: The name of the plist file (without extension)
    ///   - bundle: The bundle containing the plist
    /// - Throws: ConfigurationError if the plist cannot be read or parsed
    public required init(named plist: String, from bundle: Bundle) throws {
        let plistData = try Self.readPlist(named: plist, from: bundle)
        try parse(config: plistData)
    }

    /// Parse the Debug.plist configuration
    public func parse(config plistData: [String: Any]) throws {
        let debugMode = Self.parseDebugMode(from: plistData)
        let logLevel = try Self.parseLogLevel(from: plistData)
        let logoFrameSizeLimit = Self.parseLogoFrameSizeLimit(from: plistData)
        self.config = DebugConfig(debugMode: debugMode, logLevel: logLevel, logoFrameSizeLimit: logoFrameSizeLimit)
    }

    /// Parse debug mode from configuration
    public static func parseDebugMode(from config: [String: Any]) -> Bool {
        return config["Debug Mode"] as? Bool ?? false
    }

    /// Parse log level from configuration
    public static func parseLogLevel(from config: [String: Any]) throws -> LogLevel {
        guard let logLevelString = config["Log Level"] as? String,
              let logLevel = LogLevel(rawValue: logLevelString) else {
            throw ConfigurationError.configFileReadFailed(reason: "Invalid or missing log level in Debug.plist")
        }
        return logLevel
    }

    /// Parse logo frame size limit from configuration
    public static func parseLogoFrameSizeLimit(from config: [String: Any]) -> Double {
        return config["Logo Frame Size Limit"] as? Double ?? 0.25
    }
}
