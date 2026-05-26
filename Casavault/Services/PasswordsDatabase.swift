//
//  PasswordsDatabase.swift
//  CasaVault
//
//  Created by Lior Shor on 16/01/2026.
//

import Foundation
import CoreData
import Dependencies

extension DependencyValues {
    var swiftData: PasswordsDatabase {
        get { self[PasswordsDatabase.self] }
        set { self[PasswordsDatabase.self] = newValue }
    }
}

struct PasswordsDatabase {
    var fetchAll: @MainActor @Sendable () throws -> [Password]
    var add: @MainActor @Sendable (Password) throws -> Void
    var delete: @MainActor @Sendable (Password) throws -> Void
    var update: @MainActor @Sendable (Password) throws -> Void

    enum PasswordError: Error {
        case add
        case delete
        case update
    }
}

extension PasswordsDatabase: DependencyKey {
    public static let liveValue = Self(
        fetchAll: { @MainActor in
            do {
                @Dependency(\.databaseService.context) var context
                let passwordContext = try context()

                let fetchRequest: NSFetchRequest<Password> = NSFetchRequest(entityName: "Password")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                return try passwordContext.fetch(fetchRequest)
            } catch {
                return []
            }
        },
        add: { @MainActor model in
            @Dependency(\.databaseService) var database

            // Model is already inserted in the context via init
            do {
                try database.saveContext()
            } catch {
                throw PasswordError.add
            }
        },
        delete: { @MainActor model in
            do {
                @Dependency(\.databaseService) var database
                @Dependency(\.databaseService.context) var context
                let passwordContext = try context()

                passwordContext.delete(model)
                try database.saveContext()
            } catch {
                throw PasswordError.delete
            }
        },
        update: { @MainActor model in
            do {
                @Dependency(\.databaseService) var database
                model.updatedAt = Date()
                try database.saveContext()
            } catch {
                throw PasswordError.update
            }
        }
    )
}

extension PasswordsDatabase: TestDependencyKey {
    public static var previewValue = Self.noop

    public static let testValue = Self(
        fetchAll: unimplemented("\(Self.self).fetch"),
        add: unimplemented("\(Self.self).add"),
        delete: unimplemented("\(Self.self).delete"),
        update: unimplemented("\(Self.self).update")
    )

    static let noop = Self(
        fetchAll: { [] },
        add: { _ in },
        delete: { _ in },
        update: { _ in }
    )
}
