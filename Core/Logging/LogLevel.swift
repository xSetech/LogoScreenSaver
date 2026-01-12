// SPDX-License-Identifier: Apache-2.0

import Foundation
import OSLog

public enum LogLevel: String {
    case error = "E"
    case warning = "W"
    case info = "I"
    case debug = "D"

    public mutating func cycleNext() {
        switch self {
        case .error:   self = .warning
        case .warning: self = .info
        case .info:    self = .debug
        case .debug:   self = .error
        }
    }

    public func shouldShow(_ entryLevel: LogEntry.Level) -> Bool {
        switch self {
        case .error:
            return entryLevel == .error
        case .warning:
            return entryLevel == .warning || entryLevel == .error
        case .info:
            return entryLevel == .info || entryLevel == .warning || entryLevel == .error
        case .debug:
            return true
        }
    }
}
