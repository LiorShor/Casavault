//
//  DataBase.swift
//  CasaVault
//
//  Created by Lior Shor on 16/01/2026.
//

import Foundation
import CoreData
import Dependencies

extension DependencyValues {
    var databaseService: Database {
        get { self[Database.self] }
        set { self[Database.self] = newValue }
    }
}

struct Database {
    var context: () throws -> NSManagedObjectContext
    var saveContext: () throws -> Void
}

extension Database: DependencyKey {
    public static let liveValue = Self(
        context: { CoreDataStack.shared.viewContext },
        saveContext: { CoreDataStack.shared.saveContext() }
    )
}

extension Database: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        context: unimplemented("\(Self.self).context"),
        saveContext: unimplemented("\(Self.self).saveContext")
    )
    
    static let noop = Self(
        context: unimplemented("\(Self.self).context"),
        saveContext: unimplemented("\(Self.self).saveContext")
    )
}
