import CoreData
@testable import StorePass

// MARK: - In-memory Core Data stack

enum TestCoreDataStack {
    static func makeContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "StorePassTests", managedObjectModel: makeModel())
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error { fatalError(error.localizedDescription) }
        }
        return container.viewContext
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let homeEntity = makeHomeEntity()
        let passwordEntity = makePasswordEntity()
        let attachmentEntity = makeAttachmentEntity()
        setupRelationships(home: homeEntity, password: passwordEntity, attachment: attachmentEntity)
        model.entities = [homeEntity, passwordEntity, attachmentEntity]
        return model
    }

    private static func makeHomeEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Home"
        entity.managedObjectClassName = "Home"
        entity.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType),
            boolAttr("isDefault", default: false),
            attr("homeKitUniqueIdentifier", .UUIDAttributeType),
            attr("createdAt", .dateAttributeType),
            attr("updatedAt", .dateAttributeType),
        ]
        return entity
    }

    private static func makePasswordEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Password"
        entity.managedObjectClassName = "Password"
        entity.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType),
            attr("value", .stringAttributeType),
            attr("room", .stringAttributeType),
            attr("icon", .stringAttributeType),
            attr("homeId", .UUIDAttributeType),
            attr("homeKitUniqueIdentifier", .UUIDAttributeType),
            attr("notes", .stringAttributeType),
            attr("createdAt", .dateAttributeType),
            attr("updatedAt", .dateAttributeType),
        ]
        return entity
    }

    private static func makeAttachmentEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PasswordAttachment"
        entity.managedObjectClassName = "PasswordAttachment"
        let imageData = NSAttributeDescription()
        imageData.name = "imageData"
        imageData.attributeType = .binaryDataAttributeType
        imageData.isOptional = true
        imageData.allowsExternalBinaryDataStorage = true
        entity.properties = [
            attr("id", .UUIDAttributeType),
            imageData,
            attr("fileName", .stringAttributeType),
            attr("createdAt", .dateAttributeType),
        ]
        return entity
    }

    private static func setupRelationships(
        home: NSEntityDescription,
        password: NSEntityDescription,
        attachment: NSEntityDescription
    ) {
        let homeToPasswords = relationship("passwords", to: password, maxCount: 0, deleteRule: .cascadeDeleteRule)
        let passwordToHome = relationship("home", to: home, maxCount: 1, deleteRule: .nullifyDeleteRule)
        homeToPasswords.inverseRelationship = passwordToHome
        passwordToHome.inverseRelationship = homeToPasswords
        home.properties.append(homeToPasswords)
        password.properties.append(passwordToHome)

        let passwordToAttachments = relationship("attachments", to: attachment, maxCount: 0, deleteRule: .cascadeDeleteRule)
        let attachmentToPassword = relationship("password", to: password, maxCount: 1, deleteRule: .nullifyDeleteRule)
        passwordToAttachments.inverseRelationship = attachmentToPassword
        attachmentToPassword.inverseRelationship = passwordToAttachments
        password.properties.append(passwordToAttachments)
        attachment.properties.append(attachmentToPassword)
    }

    private static func attr(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = true
        return a
    }

    private static func boolAttr(_ name: String, default defaultValue: Bool) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .booleanAttributeType
        a.isOptional = true
        a.defaultValue = defaultValue
        return a
    }

    private static func relationship(
        _ name: String,
        to destination: NSEntityDescription,
        maxCount: Int,
        deleteRule: NSDeleteRule
    ) -> NSRelationshipDescription {
        let r = NSRelationshipDescription()
        r.name = name
        r.destinationEntity = destination
        r.isOptional = true
        r.deleteRule = deleteRule
        r.minCount = 0
        r.maxCount = maxCount
        return r
    }
}

// MARK: - Test factories

func makeTestPassword(
    in context: NSManagedObjectContext,
    name: String = "Test Device",
    homeId: UUID? = nil,
    homeKitUniqueIdentifier: UUID? = nil,
    room: String? = nil
) -> Password {
    Password(
        context: context,
        name: name,
        value: "",
        room: room,
        homeId: homeId,
        homeKitUniqueIdentifier: homeKitUniqueIdentifier
    )
}

func makeTestHome(
    in context: NSManagedObjectContext,
    name: String = "Test Home",
    isDefault: Bool = false,
    homeKitUniqueIdentifier: UUID? = nil
) -> Home {
    Home(context: context, name: name, isDefault: isDefault, homeKitUniqueIdentifier: homeKitUniqueIdentifier)
}

// MARK: - HomeKitDevice convenience init for tests

extension HomeKitDevice {
    init(name: String, roomName: String? = nil, uniqueIdentifier: UUID = UUID()) {
        self.init(name: name, roomName: roomName, categoryType: "Test", uniqueIdentifier: uniqueIdentifier)
    }
}
