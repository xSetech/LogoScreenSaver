// SPDX-License-Identifier: Apache-2.0

import Cocoa
import CoreVideo
import OSLog
#if SWIFT_PACKAGE
import LogoScreenSaverCore
#endif

/// NSView that wraps LogoAnimator for standalone app use
class AppView: NSView, AnimationHost {

    private var animator: Animator!

    /// Display link for rendering at screen refresh rate
    private var displayLink: CVDisplayLink?
    private var isAnimating: Bool = false
    private var lastStatsTime: Date = Date()

    /// Palette cycling state
    private var currentPaletteIndex: Int = 0
    private lazy var paletteNames: [String] = {
        return Array(animator.configuration.colorConfig.palettes.keys).sorted()
    }()

    /// Controls key renderer (App-specific, shown in debug mode)
    private let controlsKeyRenderer = ControlsKeyRenderer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initApp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initApp()
    }

    private func initApp() {
        do {
            animator = try Animator(bundle: CoreBundle.bundle)
            try animator.setup(host: self, in: bounds)

            // App always starts with debug mode enabled
            animator.setDebugMode(true)
        } catch {
            LogoLogger.animation.error("Failed to initialize animator: \(error.localizedDescription)")
            fatalError("Failed to initialize animator: \(error)")
        }

        logConfiguration()
        setupDisplayLink()
        startAnimation()
    }

    deinit {
        stopAnimation()
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }

    // MARK: - Display Link Setup

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        let result = CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard result == kCVReturnSuccess, let displayLink = link else {
            LogoLogger.animation.error("Failed to create CVDisplayLink")
            return
        }

        self.displayLink = displayLink

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, displayLinkContext -> CVReturn in
            let view = Unmanaged<AppView>.fromOpaque(displayLinkContext!).takeUnretainedValue()
            view.renderFrame()
            return kCVReturnSuccess
        }

        CVDisplayLinkSetOutputCallback(displayLink, callback, Unmanaged.passUnretained(self).toOpaque())

        LogoLogger.animation.info("CVDisplayLink created successfully")
    }

    // MARK: - Animation Control

    func startAnimation() {
        guard !isAnimating else { return }

        animator.startAnimation()
        isAnimating = true

        if let displayLink = displayLink {
            CVDisplayLinkStart(displayLink)
            LogoLogger.animation.info("Animation started")
        }
    }

    func stopAnimation() {
        guard isAnimating else { return }

        isAnimating = false

        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
            LogoLogger.animation.info("Animation stopped")
        }
    }

    /// Restart with new settings after configuration change
    func restartAnimation() {
        stopAnimation()

        do {
            animator = try Animator(bundle: CoreBundle.bundle)
            try animator.setup(host: self, in: bounds)
        } catch {
            LogoLogger.animation.error("Failed to restart animator: \(error.localizedDescription)")
            fatalError("Failed to restart animator: \(error)")
        }

        logConfiguration()
        startAnimation()
        LogoLogger.animation.info("Animation restarted with new configuration")
    }

    // MARK: - Rendering

    /// Render a single frame (called by CVDisplayLink)
    private func renderFrame() {
        animator.animateOneFrame()

        // Trigger redraw on main thread
        DispatchQueue.main.async { [weak self] in
            self?.needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        animator.draw(dirtyRect, hostFrame: bounds)

        // Draw controls key legend (App-specific, shown only in debug mode)
        if animator.debugState.isEnabled {
            controlsKeyRenderer.draw(in: bounds)
        }
    }

    // MARK: - AnimationHost Protocol

    override var frame: NSRect {
        get { super.frame }
        set {
            super.frame = newValue
        }
    }

    override var isFlipped: Bool {
        return true
    }

    // MARK: - View Lifecycle

    /// Called when the view is added to a window
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil {
            startAnimation()
        } else {
            stopAnimation()
        }
    }

    // MARK: - Logging

    private func logConfiguration() {
        let config = animator.configuration!
        let debugDesc = config.debugConfig.debugMode ? "enabled" : "disabled"
        LogoLogger.configuration.info("""
            Configuration loaded:
              Palette: \(config.colorConfig.defaultPalette ?? "None")
              Selection: random
              Sizing: 128x128
              Debug Mode: \(debugDesc)
              Logo Count: \(config.logoConfig.entries.count)
            """)
    }

    // MARK: - Keyboard Controls

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func keyDown(with event: NSEvent) {
        if handleSpecialKeyCode(event.keyCode) {
            return
        }

        guard let characters = event.charactersIgnoringModifiers else {
            super.keyDown(with: event)
            return
        }

        if handleCharacterKey(characters) {
            return
        }

        super.keyDown(with: event)
    }

    private func handleSpecialKeyCode(_ keyCode: UInt16) -> Bool {
        switch keyCode {
        case 123: // Left arrow
            handleCyclePreviousLogo()
            return true
        case 124: // Right arrow
            handleCycleNextLogo()
            return true
        case 126: // Up arrow
            handleIncreaseSpeed()
            return true
        case 125: // Down arrow
            handleDecreaseSpeed()
            return true
        case 53: // Escape
            handleResetLogo()
            return true
        case 48: // Tab
            handleCyclePalette()
            return true
        default:
            return false
        }
    }

    private func handleCharacterKey(_ characters: String) -> Bool {
        switch characters {
        case "0":
            handleStopLogo()
            return true
        case "`", "~":
            handleToggleDebug()
            return true
        case "l", "L":
            handleCycleLogLevel()
            return true
        default:
            return false
        }
    }

    private func handleCycleNextLogo() {
        do {
            try animator.scene.cycleToNextLogo(in: bounds)
            setNeedsDisplay(bounds)
        } catch {
            LogoLogger.animation.error("Failed to cycle to next logo: \(error.localizedDescription)")
        }
    }

    private func handleCyclePreviousLogo() {
        do {
            try animator.scene.cycleToPreviousLogo(in: bounds)
            setNeedsDisplay(bounds)
        } catch {
            LogoLogger.animation.error("Failed to cycle to previous logo: \(error.localizedDescription)")
        }
    }

    private func handleIncreaseSpeed() {
        animator.scene.increaseSpeed()
    }

    private func handleDecreaseSpeed() {
        animator.scene.decreaseSpeed()
    }

    private func handleResetLogo() {
        animator.scene.initLogo(in: bounds)
        setNeedsDisplay(bounds)
    }

    private func handleStopLogo() {
        animator.scene.stopLogo()
    }

    private func handleCyclePalette() {
        currentPaletteIndex = (currentPaletteIndex + 1) % paletteNames.count
        let newPalette = paletteNames[currentPaletteIndex]
        animator.scene.updateColorPalette(newPalette)
        LogoLogger.palette.info("Cycled to palette: \(newPalette) (index \(currentPaletteIndex)/\(paletteNames.count))")
        setNeedsDisplay(bounds)
    }

    private func handleToggleDebug() {
        animator.toggleDebugMode()
        setNeedsDisplay(bounds)
    }

    private func handleCycleLogLevel() {
        animator.cycleLogLevel()
        setNeedsDisplay(bounds)
    }
}

// MARK: - App-Specific Scene Extensions

fileprivate extension Scene {

    // MARK: - Speed Control

    func increaseSpeed() {
        if logoVelocity == .zero {
            logoVelocity = randomVelocity()
        } else {
            logoVelocity = CGVector(
                dx: logoVelocity.dx * 1.2,
                dy: logoVelocity.dy * 1.2
            )
        }
    }

    func decreaseSpeed() {
        logoVelocity = CGVector(
            dx: logoVelocity.dx / 1.2,
            dy: logoVelocity.dy / 1.2
        )
    }

    func stopLogo() {
        logoVelocity = .zero
    }

    // MARK: - Logo Cycling

    func cycleToNextLogo(in frame: CGRect) throws {
        guard !configEntries.isEmpty else { return }

        let oldVelocity = logoVelocity
        let oldPosition = logo.boundingRect.origin

        // Increment index and load logo at that index
        currentIndex = (currentIndex + 1) % configEntries.count
        logo = try loadLogoAtIndex(currentIndex, in: frame)

        // Preserve velocity and position if new logo fits
        logoVelocity = oldVelocity
        let validRegion = logoRegion(in: frame)
        if validRegion.containsInclusive(oldPosition) {
            logo.boundingRect.origin = oldPosition
        } else {
            logo.boundingRect.origin = randomLocation(in: validRegion)
        }

        // Recolor with current palette
        if let color = colorPalette?.onCollision() {
            logo.color = color
        }
    }

    func cycleToPreviousLogo(in frame: CGRect) throws {
        guard !configEntries.isEmpty else { return }

        let oldVelocity = logoVelocity
        let oldPosition = logo.boundingRect.origin

        // Decrement index and load logo at that index
        currentIndex = (currentIndex - 1 + configEntries.count) % configEntries.count
        logo = try loadLogoAtIndex(currentIndex, in: frame)

        // Preserve velocity and position if new logo fits
        logoVelocity = oldVelocity
        let validRegion = logoRegion(in: frame)
        if validRegion.containsInclusive(oldPosition) {
            logo.boundingRect.origin = oldPosition
        } else {
            logo.boundingRect.origin = randomLocation(in: validRegion)
        }

        // Recolor with current palette
        if let color = colorPalette?.onCollision() {
            logo.color = color
        }
    }

    // MARK: - Palette Control

    func updateColorPalette(_ paletteName: String) {
        // Look up palette by name
        if let palette = colorPalettes[paletteName] {
            colorPalette = palette
            if let newColor = colorPalette?.onCollision() {
                logo.color = newColor
            }
        } else if paletteName == "None" {
            colorPalette = nil
        } else {
            LogoLogger.palette.error("Palette '\(paletteName)' not found")
        }
    }

}

// MARK: - App-Specific Animator Extensions

fileprivate extension Animator {

    func cycleLogLevel() {
        debugState.logLevel.cycleNext()
    }

}
