// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit

/// Constants and settings loaded from plists
public class Configuration {

    public let frameRate: Int = 60
    public let logoSpeedPixelsPerFrame: Double = 1.0
    public let initMargin: Double = 16.0

    public let logoConfig: LogoConfig
    public let colorConfig: ColorConfig
    public let debugConfig: DebugConfig

    internal let bundle: Bundle

    /// Initialize configuration with bundle and optional plist loading
    /// - Parameters:
    ///   - bundle: The bundle containing configuration plists and resources
    ///   - skipConfigPlist: If true, skip loading plists (for tests)
    /// - Throws: ConfigurationError if plist cannot be read (when skipConfigPlist is false)
    public init(
        bundle: Bundle,
        skipConfigPlist: Bool = false
    ) throws {
        self.bundle = bundle

        if skipConfigPlist {
            self.logoConfig = LogoConfig()
            self.colorConfig = ColorConfig()
            self.debugConfig = DebugConfig()
        } else {
            let logosPlist = try LogosPlist(named: "Logos", from: bundle)
            self.logoConfig = logosPlist.config

            let colorsPlist = try ColorsPlist(named: "Colors", from: bundle)
            self.colorConfig = colorsPlist.config

            let debugPlist = try DebugPlist(named: "Debug", from: bundle)
            self.debugConfig = debugPlist.config
        }
    }

}
