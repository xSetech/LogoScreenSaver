// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit
import QuartzCore

// MARK: - Public State Model

public struct DebugOverlayState {
    public var isEnabled: Bool = false
    public var version: VersionInfo
    public var timing: Timing = .init()
    public var animation: AnimationDebugSnapshot?
    public var logLevel: LogLevel = .info

    public init(isEnabled: Bool = false, version: VersionInfo) {
        self.isEnabled = isEnabled
        self.version = version
    }
}

public struct VersionInfo {
    public var appName: String
    public var version: String
    public var sdkName: String
    public var xcodeVer: String
    public var hostVer: String
    public var commitHash: String
    public var isDirty: Bool
    public var buildTimestamp: String

    public init(
        appName: String,
        version: String,
        sdkName: String,
        xcodeVer: String,
        hostVer: String,
        commitHash: String = "unknown",
        isDirty: Bool = false,
        buildTimestamp: String = ""
    ) {
        self.appName = appName
        self.version = version
        self.sdkName = sdkName
        self.xcodeVer = xcodeVer
        self.hostVer = hostVer
        self.commitHash = commitHash
        self.isDirty = isDirty
        self.buildTimestamp = buildTimestamp
    }

    public static func fromBundle(_ bundle: Bundle, appNameFallback: String = "App") -> VersionInfo {
        let dict = bundle.infoDictionary ?? [:]
        let appName = (dict["CFBundleName"] as? String) ?? appNameFallback
        return VersionInfo(
            appName: appName,
            version: dict["CFBundleShortVersionString"] as? String ?? "Unknown",
            sdkName: dict["DTSDKName"] as? String ?? "Unknown",
            xcodeVer: dict["DTXcodeBuild"] as? String ?? "Unknown",
            hostVer: dict["BuildMachineOSBuild"] as? String ?? "Unknown",
            commitHash: BuildInfo.commitHash,
            isDirty: BuildInfo.isDirty,
            buildTimestamp: BuildInfo.buildTimestamp
        )
    }
}

public struct Timing {
    public var lastDrawStartTime: CFAbsoluteTime = 0
    public var previousDrawStartTime: CFAbsoluteTime = 0
    public var lastDrawEndTime: CFAbsoluteTime = 0
    public var previousDrawDuration: Double = 0
    public var lastAnimationEndTime: CFAbsoluteTime = 0

    public mutating func markDrawStart() {
        previousDrawStartTime = lastDrawStartTime
        lastDrawStartTime = CACurrentMediaTime()
    }

    public mutating func markDrawEnd() {
        lastDrawEndTime = CACurrentMediaTime()
        previousDrawDuration = lastDrawEndTime - lastDrawStartTime
    }

    public var drawDurationSeconds: Double {
        previousDrawDuration
    }

    public var frameIntervalSeconds: Double {
        lastDrawStartTime - previousDrawStartTime
    }
}

public struct AnimationDebugSnapshot {
    public var paletteName: String
    public var initialVelocity: CGVector
    public var initialOrigin: CGPoint
    public var currentVelocity: CGVector
    public var currentOrigin: CGPoint

    /// Used to compute animation duration.
    public var animationStartTime: CFAbsoluteTime

    /// Used to compute previous frame duration (time between animations).
    public var previousAnimationEndTime: CFAbsoluteTime

    public init(
        paletteName: String,
        initialVelocity: CGVector,
        initialOrigin: CGPoint,
        currentVelocity: CGVector,
        currentOrigin: CGPoint,
        animationStartTime: CFAbsoluteTime,
        previousAnimationEndTime: CFAbsoluteTime
    ) {
        self.paletteName = paletteName
        self.initialVelocity = initialVelocity
        self.initialOrigin = initialOrigin
        self.currentVelocity = currentVelocity
        self.currentOrigin = currentOrigin
        self.animationStartTime = animationStartTime
        self.previousAnimationEndTime = previousAnimationEndTime
    }

    public var animationDurationSeconds: Double {
        CACurrentMediaTime() - animationStartTime
    }

    public var frameDurationSeconds: Double {
        animationStartTime - previousAnimationEndTime
    }
}

// MARK: - Renderer

public final class DebugOverlayRenderer {

    private let font: NSFont
    private let textAttrs: [NSAttributedString.Key: Any]
    private let dimTextAttrs: [NSAttributedString.Key: Any]
    private let padding: CGFloat = 8
    private let gap: CGFloat = 8
    private let tablePadding: CGFloat = 8
    private var maxTableSize: CGSize = .zero

    public init(fontSize: CGFloat = 12) {
        self.font = NSFont(name: "Monaco", size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        self.textAttrs = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        self.dimTextAttrs = [
            .font: font,
            .foregroundColor: NSColor(white: 1.0, alpha: 0.85)
        ]
    }

    public func draw(in frame: NSRect, state: DebugOverlayState, logs ringBuffer: LogRingBuffer) {
        guard state.isEnabled else { return }

        let content = buildContent(state: state, frame: frame)
        let layout = calculateLayout(content: content, frame: frame)

        drawTopContent(content: content, layout: layout, frame: frame)
        drawBottomLogs(
            ringBuffer: ringBuffer,
            frame: frame,
            topOccupiedHeight: layout.topOccupiedHeight,
            logLevel: state.logLevel
        )
    }

    private struct ContentInfo {
        let versionAttr: NSAttributedString
        let copyrightAttr: NSAttributedString
        let tableRows: [TableRow]
    }

    private func buildContent(
        state: DebugOverlayState,
        frame: NSRect
    ) -> ContentInfo {
        var versionLine = "\(state.version.appName) - Version \(state.version.version)"
        if state.version.commitHash != "unknown" && !state.version.commitHash.isEmpty {
            let shortHash = String(state.version.commitHash.prefix(7))
            versionLine += " (\(shortHash))"
            if state.version.isDirty {
                versionLine += " [dirty]"
            }
        }
        versionLine += ", SDK \(state.version.sdkName), XCode \(state.version.xcodeVer), OS \(state.version.hostVer)"
        let versionAttr = NSAttributedString(string: versionLine, attributes: textAttrs)

        let copyrightText = """
        © 2026 Seth Junot, Maxwell Estes, and contributors — Licensed under Apache-2.0

        License text: https://www.apache.org/licenses/LICENSE-2.0
        Source code:  https://github.com/xSetech/LogoScreenSaver
        """
        let copyrightAttr = NSAttributedString(string: copyrightText, attributes: dimTextAttrs)

        let tableRows = makeTopRightRows(state: state, frame: frame)

        return ContentInfo(
            versionAttr: versionAttr,
            copyrightAttr: copyrightAttr,
            tableRows: tableRows
        )
    }

    private struct LayoutInfo {
        let leftMaxWidth: CGFloat
        let versionSize: NSSize
        let copyrightSize: NSSize
        let tableSize: NSSize
        let topOccupiedHeight: CGFloat
    }

    private func calculateLayout(
        content: ContentInfo,
        frame: NSRect
    ) -> LayoutInfo {
        let leftMaxWidth = max(280, min(frame.width * 0.62, 760))
        let versionSize = measureSingleLine(content.versionAttr)
        let copyrightSize = measureWrapped(content.copyrightAttr, maxWidth: leftMaxWidth)
        let leftBlockHeight = versionSize.height + gap + copyrightSize.height

        let currentTableSize = measureTable(content.tableRows)
        maxTableSize.width = max(maxTableSize.width, currentTableSize.width)
        maxTableSize.height = max(maxTableSize.height, currentTableSize.height)
        let tableSize = maxTableSize

        let topOccupiedHeight = max(leftBlockHeight, tableSize.height)

        return LayoutInfo(
            leftMaxWidth: leftMaxWidth,
            versionSize: versionSize,
            copyrightSize: copyrightSize,
            tableSize: tableSize,
            topOccupiedHeight: topOccupiedHeight
        )
    }

    private func drawTopContent(
        content: ContentInfo,
        layout: LayoutInfo,
        frame: NSRect
    ) {
        let topY = frame.maxY - padding

        let versionOrigin = CGPoint(x: frame.minX + padding, y: topY - layout.versionSize.height)
        content.versionAttr.draw(at: versionOrigin)

        let copyrightRect = CGRect(
            x: frame.minX + padding,
            y: versionOrigin.y - gap - layout.copyrightSize.height,
            width: layout.leftMaxWidth,
            height: layout.copyrightSize.height
        )
        drawWrapped(content.copyrightAttr, in: copyrightRect)

        let tableRect = CGRect(
            x: frame.maxX - padding - layout.tableSize.width,
            y: frame.maxY - padding - layout.tableSize.height,
            width: layout.tableSize.width,
            height: layout.tableSize.height
        )
        drawTable(content.tableRows, in: tableRect)
    }

    private func drawBottomLogs(
        ringBuffer: LogRingBuffer,
        frame: NSRect,
        topOccupiedHeight: CGFloat,
        logLevel: LogLevel
    ) {
        let availableTopY = frame.maxY - padding - topOccupiedHeight - gap
        let logsBottomY = frame.minY + padding
        let availableForLogs = max(0, availableTopY - logsBottomY)
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let maxLinesThatFit = Int(floor(availableForLogs / lineHeight))

        if maxLinesThatFit > 0 {
            let logContext = LogDrawingContext(
                frame: frame,
                ringBuffer: ringBuffer,
                lineHeight: lineHeight,
                lineCount: maxLinesThatFit,
                bottomY: logsBottomY,
                logLevel: logLevel
            )
            drawLogsBottomAnchored(context: logContext)
        }
    }
}

// MARK: - Top-right table (key/value)

public extension DebugOverlayRenderer {
    struct TableRow {
        public let key: String
        public let value: String
        public let valueColor: NSColor?

        public init(key: String, value: String, valueColor: NSColor? = nil) {
            self.key = key
            self.value = value
            self.valueColor = valueColor
        }
    }
}

private extension DebugOverlayRenderer {

    func makeTopRightRows(state: DebugOverlayState, frame: NSRect) -> [TableRow] {
        var rows: [TableRow] = []

        // System info
        rows.append(TableRow(key: "frame size", value: "(\(Int(frame.width)), \(Int(frame.height)))", valueColor: nil))
        rows.append(TableRow(key: "loglevel", value: state.logLevel.rawValue, valueColor: nil))

        // Timing group
        rows.append(TableRow(key: "frame", value: String(format: "%.6fs", state.timing.frameIntervalSeconds), valueColor: nil))
        rows.append(TableRow(key: "draw time", value: String(format: "%.6fs", state.timing.drawDurationSeconds), valueColor: nil))

        if let a = state.animation {
            rows.append(TableRow(key: "step time", value: String(format: "%.6fs", a.animationDurationSeconds), valueColor: nil))

            // Animation info
            rows.append(TableRow(key: "palette", value: a.paletteName, valueColor: nil))
            rows.append(TableRow(key: "initial vector", value: "(\(String(format: "%.2f", a.initialVelocity.dx)), \(String(format: "%.2f", a.initialVelocity.dy)))", valueColor: nil))
            rows.append(TableRow(key: "initial origin", value: "(\(String(format: "%.2f", a.initialOrigin.x)), \(String(format: "%.2f", a.initialOrigin.y)))", valueColor: nil))
            rows.append(TableRow(key: "vector", value: "(\(String(format: "%.2f", a.currentVelocity.dx)), \(String(format: "%.2f", a.currentVelocity.dy)))", valueColor: nil))
            rows.append(TableRow(key: "origin", value: "(\(String(format: "%.0f", a.currentOrigin.x)), \(String(format: "%.0f", a.currentOrigin.y)))", valueColor: nil))
        }

        return rows
    }
}

// MARK: - Bottom-anchored logs

private extension DebugOverlayRenderer {
    struct LogDrawingContext {
        let frame: NSRect
        let ringBuffer: LogRingBuffer
        let lineHeight: CGFloat
        let lineCount: Int
        let bottomY: CGFloat
        let logLevel: LogLevel
    }

    func drawLogsBottomAnchored(context: LogDrawingContext) {
        // Fetch more entries than lines to ensure we have enough when some are multi-line
        let entries = context.ringBuffer.getRecent(context.lineCount * 2)
        guard !entries.isEmpty else { return }

        let startTime = context.ringBuffer.getStartTime()

        // Convert entries to display lines (splitting multi-line messages)
        var displayLines: [(text: String, color: NSColor)] = []

        for entry in entries {
            // Filter based on current log level
            guard context.logLevel.shouldShow(entry.level) else { continue }
            let color = colorForLevel(entry.level)
            let elapsed = entry.timestamp - startTime
            let formattedPrefix = "[\(String(format: "%10.6f", elapsed))] (\(entry.level.rawValue)) \(entry.category) - "

            // Split message by newlines
            let messageLines = entry.message.split(separator: "\n", omittingEmptySubsequences: false)

            for (index, messageLine) in messageLines.enumerated() {
                if index == 0 {
                    // First line gets the full prefix
                    displayLines.append((text: formattedPrefix + messageLine, color: color))
                } else {
                    // Continuation lines are indented to align with the message content
                    let indent = String(repeating: " ", count: formattedPrefix.count)
                    displayLines.append((text: indent + messageLine, color: color))
                }
            }
        }

        // Limit to available line count (newest lines)
        let visibleLines = displayLines.suffix(context.lineCount)

        // Draw from bottom to top (oldest at bottom, newest at top)
        for (i, line) in visibleLines.enumerated() {
            let y = context.bottomY + CGFloat(i) * context.lineHeight

            let attr = NSAttributedString(
                string: line.text,
                attributes: [
                    .font: font,
                    .foregroundColor: line.color
                ]
            )

            attr.draw(at: CGPoint(x: context.frame.minX + padding, y: y))
        }
    }

    func colorForLevel(_ level: LogEntry.Level) -> NSColor {
        switch level {
        case .debug: return .systemBlue
        case .info: return .white
        case .warning: return .systemYellow
        case .error: return .systemRed
        }
    }
}

// MARK: - Text measurement + drawing helpers (fixes overlap)

public extension DebugOverlayRenderer {
    func measureSingleLine(_ s: NSAttributedString) -> CGSize {
        // Single-line measurement; accurate and fast.
        let rect = s.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                                  options: [.usesLineFragmentOrigin, .usesFontLeading])
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }

    func measureTable(_ rows: [TableRow]) -> CGSize {
        guard !rows.isEmpty else { return .zero }

        let keyWidth = rows
            .map { measureSingleLine(NSAttributedString(string: $0.key, attributes: dimTextAttrs)).width }
            .max() ?? 0

        let valueWidth = rows
            .map { measureSingleLine(NSAttributedString(string: $0.value, attributes: textAttrs)).width }
            .max() ?? 0

        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let height = CGFloat(rows.count) * lineHeight + tablePadding * 2
        let width = ceil(keyWidth + gap + valueWidth) + tablePadding * 2

        return CGSize(width: width, height: height)
    }

    func drawTable(_ rows: [TableRow], in rect: CGRect) {
        guard !rows.isEmpty else { return }

        // Soft background for readability
        NSColor(white: 0, alpha: 0.35).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8).fill()

        let keyWidth = rows
            .map { measureSingleLine(NSAttributedString(string: $0.key, attributes: dimTextAttrs)).width }
            .max() ?? 0

        let lineHeight = ceil(font.ascender - font.descender + font.leading)

        var y = rect.maxY - tablePadding - lineHeight
        for row in rows {
            let keyAttr = NSAttributedString(string: row.key, attributes: dimTextAttrs)

            let valColor = row.valueColor ?? (textAttrs[.foregroundColor] as? NSColor ?? .white)
            var valueAttrs = textAttrs
            valueAttrs[.foregroundColor] = valColor
            let valueAttr = NSAttributedString(string: row.value, attributes: valueAttrs)

            keyAttr.draw(at: CGPoint(x: rect.minX + tablePadding, y: y))
            valueAttr.draw(at: CGPoint(x: rect.minX + tablePadding + keyWidth + gap, y: y))

            y -= lineHeight
        }
    }
}

private extension DebugOverlayRenderer {

    func measureWrapped(_ s: NSAttributedString, maxWidth: CGFloat) -> CGSize {
        let rect = s.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                                  options: [.usesLineFragmentOrigin, .usesFontLeading])
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }

    func drawWrapped(_ s: NSAttributedString, in rect: CGRect) {
        s.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }

}
