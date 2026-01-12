// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit
import OSLog

/// Views that can host logo animation (supports ScreenSaverView and NSView)
public protocol AnimationHost: AnyObject {
    var frame: NSRect { get }
    var isFlipped: Bool { get }
    func setNeedsDisplay(_ rect: NSRect)
}

/// Logo animation logic independent of view framework
public class Animator {

    public private(set) var scene: Scene!
    public private(set) var configuration: Configuration!
    public var debugState: DebugOverlayState!
    private let debugRenderer = DebugOverlayRenderer()
    private var animationDrawn: Bool = true
    private weak var host: AnimationHost?

    public init(bundle: Bundle) throws {
        let versionInfo = VersionInfo.fromBundle(bundle, appNameFallback: "LogoScreenSaver")
        debugState = DebugOverlayState(isEnabled: false, version: versionInfo)
        configuration = try Configuration(bundle: bundle)
    }

    public func setup(host: AnimationHost, in frame: CGRect) throws {
        precondition(host.isFlipped, "Flipped coordinates (top-left origin) required. Set isFlipped = true on the view.")
        self.host = host
        debugState.isEnabled = configuration.debugConfig.debugMode
        debugState.logLevel = configuration.debugConfig.logLevel

        scene = Scene(
            configEntries: configuration.logoConfig.entries,
            colorPalettes: configuration.colorConfig.palettes,
            colorPalette: configuration.colorConfig.defaultPalette,
            baseSpeed: configuration.logoSpeedPixelsPerFrame,
            initMargin: configuration.initMargin,
            logoFrameSizeLimit: configuration.debugConfig.logoFrameSizeLimit
        )
        try scene.initScene(in: frame)
    }

    public func startAnimation() {
        guard let host = host else { return }
        scene.startAnimation(in: host.frame)
    }

    public func setDebugMode(_ enabled: Bool) {
        debugState.isEnabled = enabled
    }

    public func toggleDebugMode() {
        debugState.isEnabled.toggle()
    }

    public func animateOneFrame() {
        guard let host = host else { return }

        guard animationDrawn else {
            host.setNeedsDisplay(scene.logo.boundingRect)
            return
        }

        let animationStartTime = CACurrentMediaTime()

        let dirtyRegions = scene.animateOneFrame(in: host.frame)
        if !dirtyRegions.isEmpty {
            for dirtyRegion in dirtyRegions {
                host.setNeedsDisplay(dirtyRegion)
            }
            animationDrawn = false
        }

        if debugState.isEnabled {
            debugState.animation = AnimationDebugSnapshot(
                paletteName: configuration.colorConfig.defaultPalette ?? "None",
                initialVelocity: scene.initialVelocity,
                initialOrigin: scene.initialOrigin,
                currentVelocity: scene.logoVelocity,
                currentOrigin: scene.logo.boundingRect.origin,
                animationStartTime: animationStartTime,
                previousAnimationEndTime: debugState.timing.lastAnimationEndTime
            )
        }

        debugState.timing.lastAnimationEndTime = CACurrentMediaTime()
    }

    public func draw(_ rect: NSRect, hostFrame: NSRect) {
        debugState.timing.markDrawStart()

        scene.draw(rect)
        if !animationDrawn {
            animationDrawn = true
        }

        if debugState.isEnabled {
            debugRenderer.draw(in: hostFrame, state: debugState, logs: LogoLogger.ringBuffer)
        }

        debugState.timing.markDrawEnd()
    }
}
