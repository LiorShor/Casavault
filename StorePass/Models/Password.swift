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
    var createdAt: Date
    var updatedAt: Date?
    
    init(name: String, value: String, createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static func == (lhs: Password, rhs: Password) -> Bool {
        return lhs.id == rhs.id
    }
}
