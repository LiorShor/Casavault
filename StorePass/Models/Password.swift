//
//  Password.swift
//  StorePass
//
//  Created by Lior Shor on 16/01/2026.
//

import Foundation
import SwiftData

@Model
final class Password: Equatable, Identifiable {
    
    var id: UUID
    var name: String
    var value: String
    var room: String?
    var icon: String? // SF Symbol name
    var homeId: UUID? // The home this password belongs to
    var homeKitUniqueIdentifier: UUID? // For syncing with HomeKit devices
    var notes: String? // User notes for this password
    var createdAt: Date
    var updatedAt: Date?
    
    // Relationship to attachments
    @Relationship(deleteRule: .cascade, inverse: \PasswordAttachment.password)
    var attachments: [PasswordAttachment]? = []
    
    init(name: String, value: String, room: String? = nil, icon: String? = nil, homeId: UUID? = nil, homeKitUniqueIdentifier: UUID? = nil, notes: String? = nil, createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.room = room
        self.icon = icon
        self.homeId = homeId
        self.homeKitUniqueIdentifier = homeKitUniqueIdentifier
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.attachments = []
    }
    
    static func == (lhs: Password, rhs: Password) -> Bool {
        return lhs.id == rhs.id
    }
}
