// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import LogoScreenSaverCore

/// Tests for configuration validation
final class UserPreferencesConfigurationTests: XCTestCase {

    var testBundle: Bundle!

    override func setUp() {
        super.setUp()
        testBundle = Bundle.module
    }
}
