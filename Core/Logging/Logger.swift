// SPDX-License-Identifier: Apache-2.0

import Foundation
import OSLog

// MARK: - Log Entry

/// Log entry with level, timestamp, message, and category
public struct LogEntry {
    public enum Level: String {
        case debug = "D"
        case info = "I"
        case warning = "W"
        case error = "E"
    }

    public enum Category: String {
        case animation
        case configuration
        case app
        case logo
        case palette
        case scene
    }

    public let level: Level
    public let timestamp: CFAbsoluteTime
    public let message: String
    public let category: Category

    /// Format for display with relative timestamp
    public func formatted(relativeToStart startTime: CFAbsoluteTime) -> String {
        let elapsed = timestamp - startTime
        return "[\(String(format: "%10.6f", elapsed))] (\(level.rawValue)) \(category) - \(message)"
    }
}

// MARK: - Ring Buffer

/// Thread-safe circular buffer for log entries
public class LogRingBuffer {
    private let capacity: Int
    private var buffer: [LogEntry?]
    private var writeIndex: Int = 0
    private var count: Int = 0
    private let lock = NSLock()
    private let startTime: CFAbsoluteTime

    public init(capacity: Int = 100) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
        self.startTime = CFAbsoluteTimeGetCurrent()
    }

    public func append(_ entry: LogEntry) {
        lock.lock()
        defer { lock.unlock() }

        buffer[writeIndex] = entry
        writeIndex = (writeIndex + 1) % capacity
        count = min(count + 1, capacity)
    }

    /// Get most recent N entries in chronological order (oldest first)
    public func getRecent(_ n: Int) -> [LogEntry] {
        lock.lock()
        defer { lock.unlock() }

        let actualCount = min(n, count)
        guard actualCount > 0 else { return [] }

        var result: [LogEntry] = []
        let startIdx = (writeIndex - actualCount + capacity) % capacity

        for i in 0..<actualCount {
            let idx = (startIdx + i) % capacity
            if let entry = buffer[idx] {
                result.append(entry)
            }
        }

        return result
    }

    public func getStartTime() -> CFAbsoluteTime {
        return startTime
    }
}

// MARK: - Logger Wrapper

/// OSLog wrapper that also writes to ring buffer
public class LoggerWrapper {
    private let logger: Logger
    private let category: LogEntry.Category
    private let ringBuffer: LogRingBuffer

    init(logger: Logger, category: LogEntry.Category, ringBuffer: LogRingBuffer) {
        self.logger = logger
        self.category = category
        self.ringBuffer = ringBuffer
    }

    public func error(_ message: String) {
        logger.error("\(message)")
        ringBuffer.append(LogEntry(
            level: .error,
            timestamp: CFAbsoluteTimeGetCurrent(),
            message: message,
            category: category
        ))
    }

    public func warning(_ message: String) {
        logger.warning("\(message)")
        ringBuffer.append(LogEntry(
            level: .warning,
            timestamp: CFAbsoluteTimeGetCurrent(),
            message: message,
            category: category
        ))
    }

    public func info(_ message: String) {
        logger.info("\(message)")
        ringBuffer.append(LogEntry(
            level: .info,
            timestamp: CFAbsoluteTimeGetCurrent(),
            message: message,
            category: category
        ))
    }

    public func debug(_ message: String) {
        logger.debug("\(message)")
        ringBuffer.append(LogEntry(
            level: .debug,
            timestamp: CFAbsoluteTimeGetCurrent(),
            message: message,
            category: category
        ))
    }
}

// MARK: - Logo Logger

/// Centralized logging using modern Logger API with ring buffer capture
public enum LogoLogger {

    private static let subsystem = "io.github.xsetech.logoscreensaver"

    public static let ringBuffer = LogRingBuffer(capacity: 100)

    public static let animation = LoggerWrapper(
        logger: Logger(subsystem: subsystem, category: "animation"),
        category: .animation,
        ringBuffer: ringBuffer
    )

    public static let configuration = LoggerWrapper(
        logger: Logger(subsystem: subsystem, category: "configuration"),
        category: .configuration,
        ringBuffer: ringBuffer
    )

    public static let app = LoggerWrapper(
        logger: Logger(subsystem: subsystem, category: "lifecycle"),
        category: .app,
        ringBuffer: ringBuffer
    )

    public static let logo = LoggerWrapper(
        logger: Logger(subsystem: subsystem, category: "logo"),
        category: .logo,
        ringBuffer: ringBuffer
    )

    public static let palette = LoggerWrapper(
        logger: Logger(subsystem: subsystem, category: "palette"),
        category: .palette,
        ringBuffer: ringBuffer
    )

    public static let scene = LoggerWrapper(
        logger: Logger(subsystem: subsystem, category: "scene"),
        category: .scene,
        ringBuffer: ringBuffer
    )
}
