//
// PublicMessagePipelineTests.swift
// SafeRelayTests
//
// Tests for PublicMessagePipeline ordering and deduplication.
//

import Testing
import Foundation
@testable import SafeRelay

@MainActor
private final class TestPipelineDelegate: PublicMessagePipelineDelegate {
    private let dedupService = MessageDeduplicationService()
    var messages: [SafeRelayMessage] = []

    func pipelineCurrentMessages(_ pipeline: PublicMessagePipeline) -> [SafeRelayMessage] {
        messages
    }

    func pipeline(_ pipeline: PublicMessagePipeline, setMessages messages: [SafeRelayMessage]) {
        self.messages = messages
    }

    func pipeline(_ pipeline: PublicMessagePipeline, normalizeContent content: String) -> String {
        dedupService.normalizedContentKey(content)
    }

    func pipeline(_ pipeline: PublicMessagePipeline, contentTimestampForKey key: String) -> Date? {
        dedupService.contentTimestamp(forKey: key)
    }

    func pipeline(_ pipeline: PublicMessagePipeline, recordContentKey key: String, timestamp: Date) {
        dedupService.recordContentKey(key, timestamp: timestamp)
    }

    func pipelineTrimMessages(_ pipeline: PublicMessagePipeline) {}

    func pipelinePrewarmMessage(_ pipeline: PublicMessagePipeline, message: SafeRelayMessage) {}

    func pipelineSetBatchingState(_ pipeline: PublicMessagePipeline, isBatching: Bool) {}
}

struct PublicMessagePipelineTests {

    @Test @MainActor
    func flush_sortsByTimestamp() async {
        let pipeline = PublicMessagePipeline()
        let delegate = TestPipelineDelegate()
        pipeline.delegate = delegate

        let earlier = Date().addingTimeInterval(-10)
        let later = Date()

        let messageA = SafeRelayMessage(
            id: "a",
            sender: "A",
            content: "Later",
            timestamp: later,
            isRelay: false
        )
        let messageB = SafeRelayMessage(
            id: "b",
            sender: "A",
            content: "Earlier",
            timestamp: earlier,
            isRelay: false
        )

        pipeline.enqueue(messageA)
        pipeline.enqueue(messageB)
        pipeline.flushIfNeeded()

        #expect(delegate.messages.map { $0.id } == ["b", "a"])
    }

    @Test @MainActor
    func flush_deduplicatesByContentWithinWindow() async {
        let pipeline = PublicMessagePipeline()
        let delegate = TestPipelineDelegate()
        pipeline.delegate = delegate

        let now = Date()
        let messageA = SafeRelayMessage(
            id: "a",
            sender: "A",
            content: "Same",
            timestamp: now,
            isRelay: false
        )
        let messageB = SafeRelayMessage(
            id: "b",
            sender: "A",
            content: "Same",
            timestamp: now.addingTimeInterval(0.2),
            isRelay: false
        )

        pipeline.enqueue(messageA)
        pipeline.enqueue(messageB)
        pipeline.flushIfNeeded()

        #expect(delegate.messages.count == 1)
        #expect(delegate.messages.first?.content == "Same")
    }

    @Test @MainActor
    func lateInsert_meshAppendsRecentOlderMessage() async {
        let pipeline = PublicMessagePipeline()
        let delegate = TestPipelineDelegate()
        pipeline.delegate = delegate
        pipeline.updateActiveChannel(.mesh)

        let base = Date()
        let newer = SafeRelayMessage(
            id: "new",
            sender: "A",
            content: "New",
            timestamp: base,
            isRelay: false
        )
        let older = SafeRelayMessage(
            id: "old",
            sender: "A",
            content: "Old",
            timestamp: base.addingTimeInterval(-5),
            isRelay: false
        )

        delegate.messages = [newer]
        pipeline.enqueue(older)
        pipeline.flushIfNeeded()

        #expect(delegate.messages.map { $0.id } == ["new", "old"])
    }

    @Test @MainActor
    func lateInsert_locationInsertsByTimestamp() async {
        let pipeline = PublicMessagePipeline()
        let delegate = TestPipelineDelegate()
        pipeline.delegate = delegate
        pipeline.updateActiveChannel(.location(GeohashChannel(level: .city, geohash: "u4pruydq")))

        let base = Date()
        let newer = SafeRelayMessage(
            id: "new",
            sender: "A",
            content: "New",
            timestamp: base,
            isRelay: false
        )
        let older = SafeRelayMessage(
            id: "old",
            sender: "A",
            content: "Old",
            timestamp: base.addingTimeInterval(-5),
            isRelay: false
        )

        delegate.messages = [newer]
        pipeline.enqueue(older)
        pipeline.flushIfNeeded()

        #expect(delegate.messages.map { $0.id } == ["old", "new"])
    }
}
