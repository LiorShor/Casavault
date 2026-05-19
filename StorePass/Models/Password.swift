//
//  Password.swift
//  StorePass
//
//  Created by Lior Shor on 16/01/2026.
//

import Foundation
import CoreData

@objc(Password)
public class Password: NSManagedObject, Identifiable {
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var value: String
    @NSManaged public var room: String?
    @NSManaged public var icon: String?
    @NSManaged public var homeId: UUID?
    @NSManaged public var homeKitUniqueIdentifier: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Relationship to attachments (one-to-many)
    @NSManaged public var attachments: Set<PasswordAttachment>?
    
    // Relationship to home (many-to-one)
    @NSManaged public var home: Home?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdAt")
    }

    // Patch nil values on migrated records so non-optional Swift accessors don't crash
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        if primitiveValue(forKey: "id") == nil {
            setPrimitiveValue(UUID(), forKey: "id")
        }
        if (primitiveValue(forKey: "name") as? String) == nil {
            setPrimitiveValue("", forKey: "name")
        }
        if (primitiveValue(forKey: "value") as? String) == nil {
            setPrimitiveValue("", forKey: "value")
        }
    }
    
    convenience init(context: NSManagedObjectContext, name: String, value: String, room: String? = nil, icon: String? = nil, homeId: UUID? = nil, homeKitUniqueIdentifier: UUID? = nil, notes: String? = nil) {
        self.init(context: context)
        self.name = name
        self.value = value
        self.room = room
        self.icon = icon
        self.homeId = homeId
        self.homeKitUniqueIdentifier = homeKitUniqueIdentifier
        self.notes = notes
    }
}

extension Password {
    static func == (lhs: Password, rhs: Password) -> Bool {
        return lhs.id == rhs.id
    }
}
