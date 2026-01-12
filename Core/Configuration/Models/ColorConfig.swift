// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit

public struct ColorConfig {

    /// Named color palettes mapping palette name to ColorPalette instance
    public var palettes: [String: ColorPalette]

    /// Default palette name (nil or "None" means no colorization)
    public var defaultPalette: String?

    public init(palettes: [String: ColorPalette] = [:], defaultPalette: String? = "Spectrum") {
        self.palettes = palettes
        self.defaultPalette = defaultPalette
    }
}
