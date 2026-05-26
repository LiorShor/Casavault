//
//  PasswordAttachment.swift
//  CasaVault
//
//  Created by Lior Shor on 27/02/2026.
//

import Foundation
import CoreData

@objc(PasswordAttachment)
public class PasswordAttachment: NSManagedObject, Identifiable {
    
    @NSManaged public var id: UUID
    @NSManaged public var imageData: Data?
    @NSManaged public var fileName: String
    @NSManaged public var createdAt: Date
    
    // Relationship to Password (many-to-one)
    @NSManaged public var password: Password?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdAt")
        setPrimitiveValue("attachment", forKey: "fileName")
    }

    public override func awakeFromFetch() {
        super.awakeFromFetch()
        if primitiveValue(forKey: "id") == nil {
            setPrimitiveValue(UUID(), forKey: "id")
        }
        if primitiveValue(forKey: "createdAt") == nil {
            setPrimitiveValue(Date(), forKey: "createdAt")
        }
        if (primitiveValue(forKey: "fileName") as? String) == nil {
            setPrimitiveValue("attachment", forKey: "fileName")
        }
    }
    
    convenience init(context: NSManagedObjectContext, imageData: Data?, fileName: String = "attachment") {
        self.init(context: context)
        self.imageData = imageData
        self.fileName = fileName
    }
}
