//
//  PasswordAttachment.swift
//  StorePass
//
//  Created by Lior Shor on 27/02/2026.
//

import Foundation
import SwiftData

@Model
final class PasswordAttachment: Identifiable {
    var id: UUID
    var imageData: Data? // Store the image as Data
    var fileName: String
    var createdAt: Date
    
    // Relationship to Password
    var password: Password?
    
    init(imageData: Data?, fileName: String = "attachment", createdAt: Date = Date()) {
        self.id = UUID()
        self.imageData = imageData
        self.fileName = fileName
        self.createdAt = createdAt
    }
}
