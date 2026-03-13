//
//  HomeDatabase.swift
//  StorePass
//
//  Created by Lior Shor on 26/02/2026.
//

import Foundation
import CoreData
import Dependencies

extension DependencyValues {
    var homeDatabase: HomeDatabase {
        get { self[HomeDatabase.self] }
        set { self[HomeDatabase.self] = newValue }
    }
}

struct HomeDatabase {
    var fetchAll: @MainActor @Sendable () throws -> [Home]
    var add: @MainActor @Sendable (Home) throws -> Void
    var delete: @MainActor @Sendable (Home) throws -> Void
    var update: @MainActor @Sendable (Home) throws -> Void
    var getDefaultHome: @MainActor @Sendable () throws -> Home?
    var setDefaultHome: @MainActor @Sendable (Home) throws -> Void

    enum HomeError: Error {
        case add
        case delete
        case update
        case notFound
    }
}

extension HomeDatabase: DependencyKey {
    public static let liveValue = Self(
        fetchAll: { @MainActor in
            do {
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                
                let fetchRequest: NSFetchRequest<Home> = NSFetchRequest(entityName: "Home")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
                return try homeContext.fetch(fetchRequest)
            } catch {
                return []
            }
        },
        add: { @MainActor model in
            @Dependency(\.databaseService) var database
            @Dependency(\.databaseService.context) var context
            
            // Model is already inserted in the context via init
            do {
                try database.saveContext()
            } catch {
                throw HomeError.add
            }
        },
        delete: { @MainActor model in
            do {
                @Dependency(\.databaseService) var database
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                
                homeContext.delete(model)
                try database.saveContext()
            } catch {
                throw HomeError.delete
            }
        },
        update: { @MainActor model in
            do {
                @Dependency(\.databaseService) var database
                model.updatedAt = Date()
                try database.saveContext()
            } catch {
                throw HomeError.update
            }
        },
        getDefaultHome: { @MainActor in
            do {
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                
                let fetchRequest: NSFetchRequest<Home> = NSFetchRequest(entityName: "Home")
                fetchRequest.predicate = NSPredicate(format: "isDefault == YES")
                fetchRequest.fetchLimit = 1
                let homes = try homeContext.fetch(fetchRequest)
                return homes.first
            } catch {
                return nil
            }
        },
        setDefaultHome: { @MainActor home in
            do {
                @Dependency(\.databaseService) var database
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                
                // First, unset all other homes as default
                let fetchRequest: NSFetchRequest<Home> = NSFetchRequest(entityName: "Home")
                let allHomes = try homeContext.fetch(fetchRequest)
                for existingHome in allHomes {
                    existingHome.isDefault = false
                }
                
                // Set the selected home as default
                home.isDefault = true
                home.updatedAt = Date()
                
                try database.saveContext()
            } catch {
                throw HomeError.update
            }
        }
    )
}

extension HomeDatabase: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        fetchAll: unimplemented("\(Self.self).fetchAll"),
        add: unimplemented("\(Self.self).add"),
        delete: unimplemented("\(Self.self).delete"),
        update: unimplemented("\(Self.self).update"),
        getDefaultHome: unimplemented("\(Self.self).getDefaultHome"),
        setDefaultHome: unimplemented("\(Self.self).setDefaultHome")
    )
    
    static let noop = Self(
        fetchAll: { [] },
        add: { _ in },
        delete: { _ in },
        update: { _ in },
        getDefaultHome: { nil },
        setDefaultHome: { _ in }
    )
}
