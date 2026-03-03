//
// SafeRelayMessage+Preview.swift
// SafeRelay
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

extension SafeRelayMessage {
    static var preview: SafeRelayMessage {
        SafeRelayMessage(
            id: UUID().uuidString,
            sender: "John Doe",
            content: "Hello",
            timestamp: Date(),
            isRelay: false,
            originalSender: nil,
            isPrivate: false,
            recipientNickname: "Jane Doe",
            senderPeerID: nil,
            mentions: nil,
            deliveryStatus: .sent
        )
    }
}
