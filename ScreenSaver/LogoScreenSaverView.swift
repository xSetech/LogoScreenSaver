// SPDX-License-Identifier: Apache-2.0

import Foundation
import ScreenSaver
import Cocoa
import os.log
#if SWIFT_PACKAGE
import LogoScreenSaverCore
#endif

/// A bouncing logo screensaver
/// The @objc attribute is CRITICAL for macOS screensaver compatibility
@objc(LogoScreenSaverView)
@objcMembers
public class LogoScreenSaverView: ScreenSaverView, AnimationHost {

    /// Animator handling all animation logic
    var animator: Animator!

    /// ScreenSaverView.draw() clears the background, so hint to the system that
    /// any views behind this one can be ignored. Doubiously, this hint improves
    /// performance.
    public override var isOpaque: Bool {
        return true
    }

    public override var isFlipped: Bool {
        return true
    }

    /// Configuration UI removed - settings managed via Debug.plist, Logos.plist, and Colors.plist
    public override var hasConfigureSheet: Bool {
        return false
    }

    /// Required initializer called by the system
    @objc public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        initScreenSaver(frame: frame)
    }

    /// Supporting initializer for nib-based loading
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initScreenSaver(frame: frame)
    }

    /// Initialize the animator and set the rate at which animateOneFrame is called.
    private func initScreenSaver(frame: NSRect) {
        do {
            animator = try Animator(bundle: CoreBundle.bundle)
            try animator.setup(host: self, in: frame)
            animationTimeInterval = 1.0 / Double(animator.configuration.frameRate)
        } catch {
            LogoLogger.animation.error("Failed to initialize animator: \(error.localizedDescription)")
            fatalError("Failed to initialize screensaver: \(error)")
        }
    }

    /// Called as needed
    public override func draw(_ rect: NSRect) {
        super.draw(rect)
        animator.draw(rect, hostFrame: frame)
    }

    /// Called once
    public override func startAnimation() {
        super.startAnimation()
        animator.startAnimation()
    }

    /// Called at least every animationTimeInterval ms
    public override func animateOneFrame() {
        super.animateOneFrame()
        animator.animateOneFrame()
    }
}
