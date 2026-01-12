// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit
import OSLog

/// Logo representation supporting image or colorized bounding box rendering
public class Logo {

    private(set) var image: NSImage?
    public var boundingRect: CGRect = .zero
    public var color: NSColor = NSColor(white: 0.0, alpha: 0.0)

    /// Native size of the loaded image
    private(set) var nativeSize: CGSize = .zero

    public init() {
    }

    /// Load and configure logo from URL with target size based on frame
    public func load(from url: URL, frameSize: CGSize, frameSizeLimit: Double = 0.25) throws {
        let image = try loadImage(from: url)
        self.image = image

        // Compute target size based on native size and frame
        let targetSize = Self.computeTargetSize(nativeSize: image.size, frameSize: frameSize, frameSizeLimit: frameSizeLimit)
        configure(image: image, targetSize: targetSize)
    }

    /// Update logo size based on new frame size
    public func updateSize(for frameSize: CGSize, frameSizeLimit: Double = 0.25) {
        guard nativeSize != .zero else { return }
        let newTargetSize = Self.computeTargetSize(nativeSize: nativeSize, frameSize: frameSize, frameSizeLimit: frameSizeLimit)
        boundingRect.size = newTargetSize
    }

    /// Draw logo with current color (or colored rect if no image loaded)
    public func draw() {
        if let image = image {
            NSColor.clear.setFill()
            boundingRect.fill()
            image.draw(in: boundingRect)

            color.set()
            boundingRect.fill(using: .darken)
        } else {
            color.setFill()
            boundingRect.fill()
        }
    }

    /// Load image from URL
    private func loadImage(from url: URL) throws -> NSImage {
        guard let image = NSImage(contentsOf: url) else {
            LogoLogger.logo.error("Failed to load image from: \(url.path)")
            throw LogoError.imageLoadingFailed(url: url)
        }
        return image
    }

    /// Configure loaded image with target size
    private func configure(image: NSImage, targetSize: CGSize) {
        image.cacheMode = .always

        // Store native size
        nativeSize = image.size

        // Use computed target size
        boundingRect.size = targetSize
    }

    /// Compute target size for logo based on native size and frame constraints
    /// - Parameters:
    ///   - nativeSize: The original size of the logo image
    ///   - frameSize: The size of the containing frame
    ///   - frameSizeLimit: Maximum size as a fraction of frame dimensions (0.0 to 1.0)
    /// - Returns: Target size that maintains aspect ratio and doesn't exceed the frame size limit
    public static func computeTargetSize(nativeSize: CGSize, frameSize: CGSize, frameSizeLimit: Double = 0.25) -> CGSize {
        // Maximum allowed size based on frame size limit
        let maxWidth = frameSize.width * frameSizeLimit
        let maxHeight = frameSize.height * frameSizeLimit

        // Calculate scale factors for each dimension
        let scaleWidth = maxWidth / nativeSize.width
        let scaleHeight = maxHeight / nativeSize.height

        // Use the smaller scale factor to ensure logo fits within both constraints
        let scale = min(scaleWidth, scaleHeight, 1.0)  // Don't scale up beyond native size

        return CGSize(
            width: nativeSize.width * scale,
            height: nativeSize.height * scale
        )
    }
}
