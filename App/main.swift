// SPDX-License-Identifier: Apache-2.0

import Cocoa

// Traditional main entry point for Cocoa applications
// This replaces the @main attribute which wasn't working properly
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
