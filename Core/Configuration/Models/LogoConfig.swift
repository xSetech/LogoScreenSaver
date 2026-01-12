// SPDX-License-Identifier: Apache-2.0

import Foundation

public enum LogoSource: String {
    /// Builtin logo from Logos/ directory in bundle
    case builtin
    /// Absolute path on filesystem
    case path
}

public struct LogoConfigEntry {

    /// Unique identifier or filename (without extension for builtins, full path for filesystem)
    public let key: String

    /// File URL to the logo image
    public let path: URL

    /// Source type (builtin or filesystem path)
    public let source: LogoSource

    public init(key: String, path: URL, source: LogoSource) {
        self.key = key
        self.path = path
        self.source = source
    }
}

public struct LogoConfig {
    /// Array of available logo entries from configuration
    public var entries: [LogoConfigEntry]

    public init(entries: [LogoConfigEntry] = []) {
        self.entries = entries
    }
}
