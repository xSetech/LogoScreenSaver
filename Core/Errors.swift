// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit

// MARK: - Logo Errors

/// Errors during logo loading and initialization
public enum LogoError: Error {
    case imageLoadingFailed(url: URL)
    case noLogoEntriesAvailable
    case logoDimensionsExceedFrame(logoSize: CGSize, frameSize: CGSize)
}

extension LogoError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .imageLoadingFailed(let url):
            return "Failed to load image from: \(url.path)"
        case .noLogoEntriesAvailable:
            return "No logo configuration entries are available"
        case .logoDimensionsExceedFrame(let logoSize, let frameSize):
            return "Logo dimensions (\(logoSize.width)x\(logoSize.height)) exceed frame size (\(frameSize.width)x\(frameSize.height))"
        }
    }
}

// MARK: - Configuration Errors

/// Errors during configuration loading and parsing
public enum ConfigurationError: Error {
    case configFileNotFound(bundlePath: String)
    case configFileReadFailed(reason: String)
    case noColorPalettesFound
    case noValidLogoEntriesFound
    case invalidLogoEntry(key: String, reason: String)
    case invalidColorPalette(name: String, reason: String)
    case colorPaletteNotFound(name: String)
}

extension ConfigurationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .configFileNotFound(let bundlePath):
            return "Config.plist not found in bundle at path: \(bundlePath)"
        case .configFileReadFailed(let reason):
            return "Failed to read/parse Config.plist: \(reason)"
        case .noColorPalettesFound:
            return "No color palettes found in configuration"
        case .noValidLogoEntriesFound:
            return "No valid logo entries found in configuration"
        case .invalidLogoEntry(let key, let reason):
            return "Invalid logo entry '\(key)': \(reason)"
        case .invalidColorPalette(let name, let reason):
            return "Invalid color palette '\(name)': \(reason)"
        case .colorPaletteNotFound(let name):
            return "Color palette '\(name)' not found"
        }
    }
}

// MARK: - Animation Errors

/// Errors during animation
public enum AnimationError: Error {
    case colorPaletteEmpty(name: String)
    case displayLinkCreationFailed
}

extension AnimationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .colorPaletteEmpty(let name):
            return "Color palette '\(name)' not found or is empty"
        case .displayLinkCreationFailed:
            return "Failed to create CVDisplayLink"
        }
    }
}
