// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import LogoScreenSaverCore

/// Basic tests to verify test infrastructure
final class BasicTests: XCTestCase {

    /// Verify test framework is functional
    func testCanaryTest() {
        XCTAssertTrue(true, "Test infrastructure is working")
    }

    /// Verify we can import and access the module
    func testModuleImport() {
        let logo = Logo()
        XCTAssertNotNil(logo)
    }
}
