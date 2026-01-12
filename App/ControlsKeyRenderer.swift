// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit
#if SWIFT_PACKAGE
import LogoScreenSaverCore
#endif

/// Represents a keyboard binding for the controls legend
public struct KeyBinding {
    public let key: String
    public let description: String

    public init(key: String, description: String) {
        self.key = key
        self.description = description
    }
}

/// Renders keyboard controls legend in bottom-right corner (debug mode only)
public final class ControlsKeyRenderer {

    private let renderer: DebugOverlayRenderer
    private let padding: CGFloat = 8

    // Add new key bindings here and they auto-appear in UI
    private let bindings: [KeyBinding] = [
        KeyBinding(key: "←/→", description: "Cycle logo"),
        KeyBinding(key: "↑/↓", description: "Adjust speed"),
        KeyBinding(key: "Esc", description: "Reset logo"),
        KeyBinding(key: "0", description: "Stop logo"),
        KeyBinding(key: "Tab", description: "Cycle palette"),
        KeyBinding(key: "~", description: "Toggle debug"),
        KeyBinding(key: "L", description: "Cycle log level")
    ]

    public init(fontSize: CGFloat = 12) {
        self.renderer = DebugOverlayRenderer(fontSize: fontSize)
    }

    public func draw(in frame: NSRect) {
        // Convert KeyBindings to TableRows
        let rows = bindings.map { binding in
            DebugOverlayRenderer.TableRow(key: binding.key, value: binding.description)
        }

        let tableSize = renderer.measureTable(rows)
        let tableRect = CGRect(
            x: frame.maxX - padding - tableSize.width,
            y: frame.minY + padding,
            width: tableSize.width,
            height: tableSize.height
        )
        renderer.drawTable(rows, in: tableRect)
    }
}
