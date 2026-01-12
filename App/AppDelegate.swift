// SPDX-License-Identifier: Apache-2.0

import Cocoa

/// Launches the app and creates the main window
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let windowController = MainWindowController(window: nil)
        self.windowController = windowController
        windowController.showWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
