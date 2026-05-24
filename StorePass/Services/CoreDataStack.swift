//
//  CoreDataStack.swift
//  CasaVault
//
//  Created by Claude on 13/03/2026.
//

import Foundation
import CoreData
import CloudKit

class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        // Create the model programmatically
        let model = createModel()
        
        let container = NSPersistentCloudKitContainer(name: "StorePass", managedObjectModel: model)
        
        // Configure for CloudKit
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.shor.StorePass"
        )

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Automatically merge changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Model Creation
    
    private func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create entities
        let homeEntity = createHomeEntity()
        let passwordEntity = createPasswordEntity()
        let attachmentEntity = createPasswordAttachmentEntity()
        
        // Set up relationships
        setupRelationships(home: homeEntity, password: passwordEntity, attachment: attachmentEntity)
        
        model.entities = [homeEntity, passwordEntity, attachmentEntity]
        
        return model
    }
    
    private func createHomeEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Home"
        entity.managedObjectClassName = "Home"
        
        // Properties - ALL must be optional OR have default values for CloudKit
        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        id.isOptional = true
        
        let name = NSAttributeDescription()
        name.name = "name"
        name.attributeType = .stringAttributeType
        name.isOptional = true
        
        let isDefault = NSAttributeDescription()
        isDefault.name = "isDefault"
        isDefault.attributeType = .booleanAttributeType
        isDefault.isOptional = true
        isDefault.defaultValue = false
        
        let homeKitUniqueIdentifier = NSAttributeDescription()
        homeKitUniqueIdentifier.name = "homeKitUniqueIdentifier"
        homeKitUniqueIdentifier.attributeType = .UUIDAttributeType
        homeKitUniqueIdentifier.isOptional = true
        
        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = true
        
        let updatedAt = NSAttributeDescription()
        updatedAt.name = "updatedAt"
        updatedAt.attributeType = .dateAttributeType
        updatedAt.isOptional = true
        
        entity.properties = [id, name, isDefault, homeKitUniqueIdentifier, createdAt, updatedAt]

        return entity
    }
    
    private func createPasswordEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Password"
        entity.managedObjectClassName = "Password"
        
        // Properties - ALL must be optional OR have default values for CloudKit
        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        id.isOptional = true
        
        let name = NSAttributeDescription()
        name.name = "name"
        name.attributeType = .stringAttributeType
        name.isOptional = true
        
        let value = NSAttributeDescription()
        value.name = "value"
        value.attributeType = .stringAttributeType
        value.isOptional = true
        
        let room = NSAttributeDescription()
        room.name = "room"
        room.attributeType = .stringAttributeType
        room.isOptional = true
        
        let icon = NSAttributeDescription()
        icon.name = "icon"
        icon.attributeType = .stringAttributeType
        icon.isOptional = true
        
        let homeId = NSAttributeDescription()
        homeId.name = "homeId"
        homeId.attributeType = .UUIDAttributeType
        homeId.isOptional = true
        
        let homeKitUniqueIdentifier = NSAttributeDescription()
        homeKitUniqueIdentifier.name = "homeKitUniqueIdentifier"
        homeKitUniqueIdentifier.attributeType = .UUIDAttributeType
        homeKitUniqueIdentifier.isOptional = true
        
        let notes = NSAttributeDescription()
        notes.name = "notes"
        notes.attributeType = .stringAttributeType
        notes.isOptional = true
        
        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = true
        
        let updatedAt = NSAttributeDescription()
        updatedAt.name = "updatedAt"
        updatedAt.attributeType = .dateAttributeType
        updatedAt.isOptional = true
        
        entity.properties = [id, name, value, room, icon, homeId, homeKitUniqueIdentifier, notes, createdAt, updatedAt]
        
        return entity
    }
    
    private func createPasswordAttachmentEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PasswordAttachment"
        entity.managedObjectClassName = "PasswordAttachment"
        
        // Properties - ALL must be optional OR have default values for CloudKit
        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        id.isOptional = true
        
        let imageData = NSAttributeDescription()
        imageData.name = "imageData"
        imageData.attributeType = .binaryDataAttributeType
        imageData.isOptional = true
        imageData.allowsExternalBinaryDataStorage = true
        
        let fileName = NSAttributeDescription()
        fileName.name = "fileName"
        fileName.attributeType = .stringAttributeType
        fileName.isOptional = true
        
        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = true
        
        entity.properties = [id, imageData, fileName, createdAt]
        
        return entity
    }
    
    private func setupRelationships(home: NSEntityDescription, password: NSEntityDescription, attachment: NSEntityDescription) {
        // Home <-> Password relationship
        let homeToPasswords = NSRelationshipDescription()
        homeToPasswords.name = "passwords"
        homeToPasswords.destinationEntity = password
        homeToPasswords.isOptional = true
        homeToPasswords.deleteRule = .cascadeDeleteRule
        homeToPasswords.minCount = 0
        homeToPasswords.maxCount = 0 // to-many
        
        let passwordToHome = NSRelationshipDescription()
        passwordToHome.name = "home"
        passwordToHome.destinationEntity = home
        passwordToHome.isOptional = true
        passwordToHome.deleteRule = .nullifyDeleteRule
        passwordToHome.minCount = 0
        passwordToHome.maxCount = 1 // to-one
        
        homeToPasswords.inverseRelationship = passwordToHome
        passwordToHome.inverseRelationship = homeToPasswords
        
        home.properties.append(homeToPasswords)
        password.properties.append(passwordToHome)
        
        // Password <-> PasswordAttachment relationship
        let passwordToAttachments = NSRelationshipDescription()
        passwordToAttachments.name = "attachments"
        passwordToAttachments.destinationEntity = attachment
        passwordToAttachments.isOptional = true
        passwordToAttachments.deleteRule = .cascadeDeleteRule
        passwordToAttachments.minCount = 0
        passwordToAttachments.maxCount = 0 // to-many
        
        let attachmentToPassword = NSRelationshipDescription()
        attachmentToPassword.name = "password"
        attachmentToPassword.destinationEntity = password
        attachmentToPassword.isOptional = true
        attachmentToPassword.deleteRule = .nullifyDeleteRule
        attachmentToPassword.minCount = 0
        attachmentToPassword.maxCount = 1 // to-one
        
        passwordToAttachments.inverseRelationship = attachmentToPassword
        attachmentToPassword.inverseRelationship = passwordToAttachments
        
        password.properties.append(passwordToAttachments)
        attachment.properties.append(attachmentToPassword)
    }
    
    // MARK: - Saving
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - CloudKit Sharing
    
    func canShare(_ object: NSManagedObject) -> Bool {
        return persistentContainer.canUpdateRecord(forManagedObjectWith: object.objectID)
    }
    
    func share(_ objects: [NSManagedObject], to share: CKShare, completion: @escaping (Set<NSManagedObjectID>?, CKShare?, CKContainer?, Error?) -> Void) {
        persistentContainer.share(objects, to: share, completion: completion)
    }
}
