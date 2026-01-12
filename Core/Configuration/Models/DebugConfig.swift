// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct DebugConfig {

    public var debugMode: Bool
    public var logLevel: LogLevel
    public var logoFrameSizeLimit: Double

    public init(debugMode: Bool = false, logLevel: LogLevel = .info, logoFrameSizeLimit: Double = 0.25) {
        self.debugMode = debugMode
        self.logLevel = logLevel
        self.logoFrameSizeLimit = logoFrameSizeLimit
    }
}
