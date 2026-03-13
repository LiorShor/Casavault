//
//  PasswordAttachment.swift
//  StorePass
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
    
    convenience init(context: NSManagedObjectContext, imageData: Data?, fileName: String = "attachment") {
        self.init(context: context)
        self.imageData = imageData
        self.fileName = fileName
    }
}
