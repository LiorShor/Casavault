//
//  Home.swift
//  StorePass
//
//  Created by Lior Shor on 26/02/2026.
//

import Foundation
import SwiftData

@Model
final class Home: Equatable, Identifiable {
    
    var id: UUID
    var name: String
    var isDefault: Bool
    var homeKitUniqueIdentifier: UUID? // For syncing with HomeKit homes
    var createdAt: Date
    var updatedAt: Date?
    
    init(name: String, isDefault: Bool = false, homeKitUniqueIdentifier: UUID? = nil, createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.isDefault = isDefault
        self.homeKitUniqueIdentifier = homeKitUniqueIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static func == (lhs: Home, rhs: Home) -> Bool {
        return lhs.id == rhs.id
    }
}
