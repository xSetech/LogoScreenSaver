// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Helper to access the Core module's bundle containing resources
public enum CoreBundle {
    /// Returns the bundle containing Core module resources (Config.plist, logos, etc.)
    public static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        // For Xcode builds, use the class-based bundle lookup
        return Bundle(for: BundleToken.self)
        #endif
    }

    #if !SWIFT_PACKAGE
    // Token class for bundle lookup in non-SPM builds
    private final class BundleToken {}
    #endif
}
