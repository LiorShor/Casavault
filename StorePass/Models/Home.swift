//
//  Home.swift
//  CasaVault
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

    public override func awakeFromFetch() {
        super.awakeFromFetch()
        if primitiveValue(forKey: "id") == nil {
            setPrimitiveValue(UUID(), forKey: "id")
        }
        if (primitiveValue(forKey: "name") as? String) == nil {
            setPrimitiveValue("", forKey: "name")
        }
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
