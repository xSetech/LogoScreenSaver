// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit
import OSLog

/// Logo scene handling selection, movement, collision detection, and rendering
public class Scene {

    public var logo: Logo!
    public let backgroundFillColor: NSColor = .black

    // Animation configuration from Debug.plist
    private let initMargin: CGFloat
    private let baseSpeed: CGFloat
    private let logoFrameSizeLimit: Double

    public var logoVelocity: CGVector = .zero
    public var initialVelocity: CGVector = .zero
    public var initialOrigin: CGPoint = .zero

    public var configEntries: [LogoConfigEntry]
    public var currentIndex: Int = 0
    public var colorPalettes: [String: ColorPalette]
    public var colorPalette: ColorPalette?

    /// Track current frame size to detect changes
    private var currentFrameSize: CGSize = .zero

    public init(
        configEntries: [LogoConfigEntry],
        colorPalettes: [String: ColorPalette],
        colorPalette: String?,
        baseSpeed: Double = 1.0,
        initMargin: Double = 16.0,
        logoFrameSizeLimit: Double = 0.25
    ) {
        self.configEntries = configEntries
        self.colorPalettes = colorPalettes
        self.baseSpeed = CGFloat(baseSpeed)
        self.initMargin = CGFloat(initMargin)
        self.logoFrameSizeLimit = logoFrameSizeLimit

        // Look up palette by name, nil or "None" means no colorization
        if let paletteName = colorPalette, paletteName != "None" {
            self.colorPalette = colorPalettes[paletteName]
            if self.colorPalette == nil {
                LogoLogger.palette.error("Selected palette '\(paletteName)' not found in configuration")
                assertionFailure("Selected palette '\(paletteName)' not found in configuration")
            }
        } else {
            self.colorPalette = nil
        }
    }

    /// Load logo, validate it fits within frame margins, assign random velocity and position
    public func initScene(in frame: CGRect) throws {
        currentFrameSize = frame.size
        logo = try loadLogo(in: frame)

        let frameWidthLessMargin = frame.width - (initMargin * 2)
        let frameHeightLessMargin = frame.height - (initMargin * 2)
        guard logo.boundingRect.size.width < frameWidthLessMargin &&
              logo.boundingRect.size.height < frameHeightLessMargin else {
            LogoLogger.logo.error("""
                Logo dimensions exceed frame size: logo=(\
                \(String(format: "%.0f", self.logo.boundingRect.size.width)), \
                \(String(format: "%.0f", self.logo.boundingRect.size.height))), frame=(\
                \(String(format: "%.0f", frameWidthLessMargin)), \
                \(String(format: "%.0f", frameHeightLessMargin)))
                """)
            throw LogoError.logoDimensionsExceedFrame(
                logoSize: logo.boundingRect.size,
                frameSize: CGSize(width: frameWidthLessMargin, height: frameHeightLessMargin)
            )
        }

        initLogo(in: frame)
    }

    public func initLogo(in frame: CGRect) {
        let regionWithMargin = logoRegion(in: frame, withMargin: initMargin)

        logoVelocity = randomVelocity()
        logo.boundingRect.origin = randomLocation(in: regionWithMargin)

        initialVelocity = logoVelocity
        initialOrigin = logo.boundingRect.origin
    }

    /// Load and configure logo based on configuration
    public func loadLogo(in frame: CGRect) throws -> Logo {
        guard !configEntries.isEmpty else {
            LogoLogger.logo.error("No logo configuration entries available")
            throw LogoError.noLogoEntriesAvailable
        }

        let logo = Logo()
        let selectedEntry = configEntries.randomElement()!

        // Load logo with frame size to compute target size
        try logo.load(from: selectedEntry.path, frameSize: frame.size, frameSizeLimit: logoFrameSizeLimit)

        LogoLogger.logo.info("""
            Loaded logo: \(selectedEntry.key) (\(selectedEntry.source.rawValue)), \
            native size: \(String(format: "%.0fx%.0f", logo.nativeSize.width, logo.nativeSize.height)), \
            target size: \(String(format: "%.0fx%.0f", logo.boundingRect.size.width, logo.boundingRect.size.height))
            """)

        return logo
    }

    /// Load logo at a specific index (for manual cycling, ignores selection mode)
    public func loadLogoAtIndex(_ index: Int, in frame: CGRect) throws -> Logo {
        guard !configEntries.isEmpty else {
            LogoLogger.logo.error("No logo configuration entries available")
            throw LogoError.noLogoEntriesAvailable
        }

        guard index >= 0 && index < configEntries.count else {
            LogoLogger.logo.error("Invalid logo index: \(index)")
            throw LogoError.noLogoEntriesAvailable
        }

        let entry = configEntries[index]
        let logo = Logo()

        // Load logo with frame size to compute target size
        try logo.load(from: entry.path, frameSize: frame.size, frameSizeLimit: logoFrameSizeLimit)

        LogoLogger.logo.info("""
            Loaded logo at index \(index): \(entry.key) (\(entry.source.rawValue)), \
            native size: \(String(format: "%.0fx%.0f", logo.nativeSize.width, logo.nativeSize.height)), \
            target size: \(String(format: "%.0fx%.0f", logo.boundingRect.size.width, logo.boundingRect.size.height))
            """)

        return logo
    }

    /// Region where logo origin stays on-screen (outside this region, logo moves off-screen)
    public func logoRegion(in frame: CGRect, withMargin margin: CGFloat = 0) -> CGRect {
        let originInFrame = CGPoint(
            x: margin, y: margin
        )
        let sizeInFrame = CGSize(
            width: frame.width - (logo.boundingRect.width + (margin * 2)),
            height: frame.height - (logo.boundingRect.height + (margin * 2))
        )
        return CGRect(origin: originInFrame, size: sizeInFrame)
    }

    public func randomVelocity() -> CGVector {
        return CGVector(
            dx: (Bool.random() ? 1 : -1) * baseSpeed,
            dy: (Bool.random() ? 1 : -1) * baseSpeed
        )
    }

    public func randomLocation(in region: CGRect) -> CGPoint {
        return CGPoint(
            x: CGFloat.random(in: region.origin.x...region.maxX),
            y: CGFloat.random(in: region.origin.y...region.maxY)
        )
    }

    // MARK: - Animation

    public func draw(_ dirtyRect: NSRect) {
        backgroundFillColor.setFill()
        dirtyRect.fill()
        if dirtyRect.intersects(logo.boundingRect) {
            logo.draw()
        }
    }

    public func startAnimation(in frame: CGRect) {
        // Get initial color from palette (onCollision advances to first color)
        if let color = colorPalette?.onCollision() {
            logo.color = color
        }

        _ = animateOneFrame(in: frame)
    }

    /// Step scene, handle collisions, return dirty regions
    public func animateOneFrame(in frame: CGRect) -> [CGRect] {
        var dirtyRegions: [CGRect] = []

        // Check if frame size has changed and update logo size accordingly
        if frame.size != currentFrameSize {
            dirtyRegions.append(logo.boundingRect)
            logo.updateSize(for: frame.size, frameSizeLimit: logoFrameSizeLimit)
            currentFrameSize = frame.size
            dirtyRegions.append(logo.boundingRect)
        }

        let validRegion = logoRegion(in: frame)

        // Window may have resized; reinit if logo moved outside valid region
        if !validRegion.containsInclusive(logo.boundingRect.origin) {
            dirtyRegions.append(logo.boundingRect)
            initLogo(in: frame)
            dirtyRegions.append(logo.boundingRect)
        }
        assert(validRegion.containsInclusive(logo.boundingRect.origin))

        if logoVelocity == .zero {
            return dirtyRegions
        }

        if dirtyRegions.isEmpty {
            dirtyRegions.append(logo.boundingRect)
        }

        let originalLogoVelocity = logoVelocity
        let elapsed = processMovementAndCollisions(validRegion: validRegion, dirtyRegions: &dirtyRegions)

        // Change color on collision (velocity change)
        if elapsed > 0 || logoVelocity != originalLogoVelocity {
            if let newColor = colorPalette?.onCollision() {
                logo.color = newColor
            }
        }

        return dirtyRegions
    }

    private func processMovementAndCollisions(validRegion: CGRect, dirtyRegions: inout [CGRect]) -> CGFloat {
        var elapsed: CGFloat = 0.0

        while elapsed < 1.0 {

            assert(validRegion.containsInclusive(logo.boundingRect.origin))

            // Proposed displacement: p₀=t0, p₁=t1, regardless of current velocity
            let step = Ray(
                p₀: logo.boundingRect.origin,
                p₁: logo.boundingRect.origin + (logoVelocity * (1 - elapsed))
            )

            if validRegion.containsInclusive(step.p₁) {
                logo.boundingRect.origin = step.p₁
                dirtyRegions.append(logo.boundingRect)
                break
            }

            // Collision: compute intersections excluding endpoint
            let intersections = step
                .intersections(with: validRegion)
                .filter({ $0.time < 1 })

            assert(!intersections.isEmpty)
            assert(intersections.count <= 4)

            for intersection in intersections {
                assert(validRegion.containsInclusive(intersection.point(on: step, within: validRegion)))
            }
            if intersections.count >= 3 {
                // Intersections >= 3 means a corner is involved
                assert(
                    (intersections[0].time == 0 && intersections[1].time == 0) ||
                    (intersections[-1].time == 0 && intersections[-2].time == 0)
                )
            }

            if intersections.count > 1 {
                // Diagonal corner crossing: use last intersection, rotate to bounce
                LogoLogger.scene.debug("Collision t=\(intersections.first!.time) Diagonal corner crossing")
                elapsed += intersections.last!.time
                logo.boundingRect.origin = intersections.last!.point(on: step, within: validRegion)
                checkCornerAndRotate(at: intersections.last!, within: validRegion, on: step)
            } else if intersections.first!.time != 0 {
                // Normal collision: move to intersection, rotate to bounce
                LogoLogger.scene.debug("Collision t=\(intersections.first!.time) Normal collision")
                elapsed += intersections.last!.time
                logo.boundingRect.origin = intersections.last!.point(on: step, within: validRegion)
                checkCornerAndRotate(at: intersections.last!, within: validRegion, on: step)
            } else {
                // Started on border, stepping outward: reverse without moving
                LogoLogger.scene.debug("Collision t=\(intersections.first!.time) Started on border, stepping outward")
                checkCornerAndRotate(at: intersections.last!, within: validRegion, on: step)
            }

        }

        assert(validRegion.containsInclusive(logo.boundingRect.origin))

        dirtyRegions.append(logo.boundingRect)

        return elapsed
    }

    private func checkCornerAndRotate(
        at intersection: Intersection,
        within region: CGRect,
        on segment: Ray,
    ) {
        // Corner collisions when dx ~= dy are cute, so they are treated specially here.
        if abs(logoVelocity.dx - logoVelocity.dy) < 0.001 {
            if let corner = intersection.nearCorner(of: region, along: segment) {
                // Because nearCorner checks if the logo is within a small radius around each
                // corner, the logo must only be turned around if it's moving into the corner.
                switch intersection.edge {
                case .left:
                    if logoVelocity.dx > 0 {
                        return
                    }
                case .right:
                    if logoVelocity.dx < 0 {
                        return
                    }
                case .top:
                    if logoVelocity.dy > 0 {
                        return
                    }
                case .bottom:
                    if logoVelocity.dy < 0 {
                        return
                    }
                }
                LogoLogger.scene.debug("Corner collision")
                logo.boundingRect.origin = corner
                logoVelocity.rotate180()
                return
            }
        }
        logoVelocity.rotate90(at: intersection)
    }

}

fileprivate extension CGVector {

    mutating func rotate180() {
        self.dx = -self.dx
        self.dy = -self.dy
    }

    mutating func rotate90(at intersection: Intersection) {
        switch intersection.edge {
        case .left, .right:
            self.dx = -self.dx
        case .top, .bottom:
            self.dy = -self.dy
        }
    }

}
