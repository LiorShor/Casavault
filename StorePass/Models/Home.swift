//
//  Home.swift
//  StorePass
//
//  Created by Lior Shor on 26/02/2026.
//

import Foundation
import CoreData

@objc(Home)
public class Home: NSManagedObject, Identifiable {
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var isDefault: Bool
    @NSManaged public var homeKitUniqueIdentifier: UUID?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date?
    
    // Relationship to passwords
    @NSManaged public var passwords: Set<Password>?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdAt")
        setPrimitiveValue(false, forKey: "isDefault")
    }
    
    convenience init(context: NSManagedObjectContext, name: String, isDefault: Bool = false, homeKitUniqueIdentifier: UUID? = nil) {
        self.init(context: context)
        self.name = name
        self.isDefault = isDefault
        self.homeKitUniqueIdentifier = homeKitUniqueIdentifier
    }
}

extension Home {
    static func == (lhs: Home, rhs: Home) -> Bool {
        return lhs.id == rhs.id
    }
}
