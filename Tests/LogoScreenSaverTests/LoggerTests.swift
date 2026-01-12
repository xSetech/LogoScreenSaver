// SPDX-License-Identifier: Apache-2.0

import XCTest
import OSLog
@testable import LogoScreenSaverCore

/// Tests for LogRingBuffer and logging infrastructure
final class LoggerTests: XCTestCase {

    // MARK: - Ring Buffer Tests

    func testRingBufferAppend() {
        let buffer = LogRingBuffer(capacity: 5)

        let entry = LogEntry(
            level: .info,
            timestamp: CFAbsoluteTimeGetCurrent(),
            message: "Test message",
            category: .animation
        )

        buffer.append(entry)
        let entries = buffer.getRecent(1)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].message, "Test message")
        XCTAssertEqual(entries[0].level, .info)
        XCTAssertEqual(entries[0].category, .animation)
    }

    func testRingBufferWrapping() {
        let buffer = LogRingBuffer(capacity: 3)

        // Add 5 entries to a buffer with capacity 3
        for i in 1...5 {
            buffer.append(LogEntry(
                level: .info,
                timestamp: CFAbsoluteTimeGetCurrent(),
                message: "Message \(i)",
                category: .animation
            ))
        }

        // Should only have the last 3 entries
        let entries = buffer.getRecent(3)
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[0].message, "Message 3")
        XCTAssertEqual(entries[1].message, "Message 4")
        XCTAssertEqual(entries[2].message, "Message 5")
    }

    func testRingBufferChronologicalOrder() {
        let buffer = LogRingBuffer(capacity: 10)

        // Add entries with increasing timestamps
        for i in 1...5 {
            buffer.append(LogEntry(
                level: .info,
                timestamp: CFAbsoluteTimeGetCurrent() + Double(i),
                message: "Message \(i)",
                category: .animation
            ))
        }

        let entries = buffer.getRecent(5)

        // Should be in chronological order (oldest first)
        for i in 0..<4 {
            XCTAssertLessThan(entries[i].timestamp, entries[i + 1].timestamp)
        }
    }

    func testRingBufferEmptyBuffer() {
        let buffer = LogRingBuffer(capacity: 10)

        let entries = buffer.getRecent(5)
        XCTAssertEqual(entries.count, 0)
    }

    func testRingBufferRequestMoreThanAvailable() {
        let buffer = LogRingBuffer(capacity: 10)

        // Add only 3 entries
        for i in 1...3 {
            buffer.append(LogEntry(
                level: .info,
                timestamp: CFAbsoluteTimeGetCurrent(),
                message: "Message \(i)",
                category: .animation
            ))
        }

        // Request 10 entries
        let entries = buffer.getRecent(10)

        // Should only get 3
        XCTAssertEqual(entries.count, 3)
    }

    func testRingBufferSingleEntry() {
        let buffer = LogRingBuffer(capacity: 10)

        buffer.append(LogEntry(
            level: .error,
            timestamp: CFAbsoluteTimeGetCurrent(),
            message: "Single message",
            category: .logo
        ))

        let entries = buffer.getRecent(1)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].message, "Single message")
        XCTAssertEqual(entries[0].level, .error)
    }

    func testRingBufferThreadSafety() {
        let buffer = LogRingBuffer(capacity: 100)
        let expectation = XCTestExpectation(description: "Concurrent writes complete")
        let iterations = 1000
        let threadCount = 10

        var completedThreads = 0
        let lock = NSLock()

        // Spawn multiple threads writing concurrently
        for threadId in 0..<threadCount {
            DispatchQueue.global().async {
                for i in 0..<iterations {
                    buffer.append(LogEntry(
                        level: .debug,
                        timestamp: CFAbsoluteTimeGetCurrent(),
                        message: "Thread \(threadId) message \(i)",
                        category: .animation
                    ))
                }

                lock.lock()
                completedThreads += 1
                if completedThreads == threadCount {
                    expectation.fulfill()
                }
                lock.unlock()
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // Should have exactly capacity entries (the most recent)
        let entries = buffer.getRecent(100)
        XCTAssertEqual(entries.count, 100)
    }

    func testRingBufferStartTime() {
        let beforeCreation = CFAbsoluteTimeGetCurrent()
        let buffer = LogRingBuffer(capacity: 10)
        let afterCreation = CFAbsoluteTimeGetCurrent()

        let startTime = buffer.getStartTime()

        XCTAssertGreaterThanOrEqual(startTime, beforeCreation)
        XCTAssertLessThanOrEqual(startTime, afterCreation)
    }

    // MARK: - Log Entry Tests

    func testLogEntryFormatted() {
        let startTime: CFAbsoluteTime = 1000.0
        let entry = LogEntry(
            level: .warning,
            timestamp: 1012.345,
            message: "Test warning",
            category: .configuration
        )

        let formatted = entry.formatted(relativeToStart: startTime)

        // Should format as "[    12.345000] (W) configuration - Test warning"
        XCTAssertTrue(formatted.hasPrefix("["))
        XCTAssertTrue(formatted.contains("12.345"))
        XCTAssertTrue(formatted.contains("(W)"))
        XCTAssertTrue(formatted.contains("configuration"))
        XCTAssertTrue(formatted.contains("Test warning"))
    }

    func testLogEntryLevelRawValues() {
        XCTAssertEqual(LogEntry.Level.debug.rawValue, "D")
        XCTAssertEqual(LogEntry.Level.info.rawValue, "I")
        XCTAssertEqual(LogEntry.Level.warning.rawValue, "W")
        XCTAssertEqual(LogEntry.Level.error.rawValue, "E")
    }

    // MARK: - Logger Wrapper Tests

    func testLoggerWrapperWritesToRingBuffer() {
        let ringBuffer = LogRingBuffer(capacity: 10)
        let logger = LoggerWrapper(
            logger: Logger(subsystem: "test", category: "test"),
            category: .animation,
            ringBuffer: ringBuffer
        )

        logger.info("Test info message")
        logger.error("Test error message")
        logger.warning("Test warning message")
        logger.debug("Test debug message")

        let entries = ringBuffer.getRecent(10)
        XCTAssertEqual(entries.count, 4)

        // Check that all messages were captured
        let messages = entries.map { $0.message }
        XCTAssertTrue(messages.contains("Test info message"))
        XCTAssertTrue(messages.contains("Test error message"))
        XCTAssertTrue(messages.contains("Test warning message"))
        XCTAssertTrue(messages.contains("Test debug message"))
    }

    func testLoggerWrapperCorrectLevels() {
        let ringBuffer = LogRingBuffer(capacity: 10)
        let logger = LoggerWrapper(
            logger: Logger(subsystem: "test", category: "test"),
            category: .logo,
            ringBuffer: ringBuffer
        )

        logger.debug("Debug")
        logger.info("Info")
        logger.warning("Warning")
        logger.error("Error")

        let entries = ringBuffer.getRecent(10)

        XCTAssertEqual(entries[0].level, .debug)
        XCTAssertEqual(entries[1].level, .info)
        XCTAssertEqual(entries[2].level, .warning)
        XCTAssertEqual(entries[3].level, .error)
    }

    func testLoggerWrapperCorrectCategory() {
        let ringBuffer = LogRingBuffer(capacity: 10)
        let logger = LoggerWrapper(
            logger: Logger(subsystem: "test", category: "test"),
            category: .configuration,
            ringBuffer: ringBuffer
        )

        logger.info("Test message")

        let entries = ringBuffer.getRecent(1)
        XCTAssertEqual(entries[0].category, .configuration)
    }

    func testLoggerWrapperTimestampPrecision() {
        let ringBuffer = LogRingBuffer(capacity: 10)
        let logger = LoggerWrapper(
            logger: Logger(subsystem: "test", category: "test"),
            category: .animation,
            ringBuffer: ringBuffer
        )

        let before = CFAbsoluteTimeGetCurrent()
        logger.info("Test message")
        let after = CFAbsoluteTimeGetCurrent()

        let entries = ringBuffer.getRecent(1)
        XCTAssertGreaterThanOrEqual(entries[0].timestamp, before)
        XCTAssertLessThanOrEqual(entries[0].timestamp, after)
    }
}
