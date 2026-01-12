// SPDX-License-Identifier: Apache-2.0

import Cocoa
import OSLog
#if SWIFT_PACKAGE
import LogoScreenSaverCore
#endif

/// Window controller rendering screensaver in app window
final class MainWindowController: NSWindowController, NSWindowDelegate {

    private var appView: AppView!

    override init(window: NSWindow?) {
        super.init(window: window)

        // Lazy loading requires explicit call when window is nil
        if window == nil {
            self.loadWindow()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadWindow() {
        let contentRect = NSRect(x: 0, y: 0, width: 1024, height: 768)
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]

        let window = NSWindow(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "LogoScreenSaverApp"

        window.title = appName
        window.center()
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("MainWindow")

        appView = AppView(frame: contentRect)
        window.contentView = appView

        self.window = window

        LogoLogger.app.info("MainWindow initialized")
    }

    func windowWillClose(_ notification: Notification) {
        appView?.stopAnimation()
        LogoLogger.app.info("Main window closing")
    }
}
