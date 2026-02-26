//
//  PasswordsDatabase.swift
//  StorePass
//
//  Created by Lior Shor on 16/01/2026.
//

import Foundation
import SwiftData
import Dependencies

extension DependencyValues {
    var swiftData: PasswordsDatabase {
        get { self[PasswordsDatabase.self] }
        set { self[PasswordsDatabase.self] = newValue }
    }
}

struct PasswordsDatabase {
    var fetchAll: @MainActor @Sendable () throws -> [Password]
    var fetch: @MainActor @Sendable (FetchDescriptor<Password>) throws -> [Password]
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
                let movieContext = try context()
                
                let descriptor = FetchDescriptor<Password>(sortBy: [SortDescriptor(\.id)])
                return try movieContext.fetch(descriptor)
            } catch {
                return []
            }
        },
        fetch: { @MainActor descriptor in
            do {
                @Dependency(\.databaseService.context) var context
                let movieContext = try context()
                return try movieContext.fetch(descriptor)
            } catch {
                return []
            }
        },
        add: { @MainActor model in
            do {
                @Dependency(\.databaseService.context) var context
                let movieContext = try context()
                
                movieContext.insert(model)
            } catch {
                throw PasswordError.add
            }
        },
        delete: { @MainActor model in
            do {
                @Dependency(\.databaseService.context) var context
                let movieContext = try context()
                
                let modelToBeDelete = model
                movieContext.delete(modelToBeDelete)
            } catch {
                throw PasswordError.delete
            }
        },
        update: { @MainActor model in
            do {
                @Dependency(\.databaseService.context) var context
                let movieContext = try context()
                
                // SwiftData automatically tracks changes to model objects
                // We just need to ensure the context saves
                try movieContext.save()
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
        fetch: unimplemented("\(Self.self).fetchDescriptor"),
        add: unimplemented("\(Self.self).add"),
        delete: unimplemented("\(Self.self).delete"),
        update: unimplemented("\(Self.self).update")
    )
    
    static let noop = Self(
        fetchAll: { [] },
        fetch: { _ in [] },
        add: { _ in },
        delete: { _ in },
        update: { _ in }
    )
}

