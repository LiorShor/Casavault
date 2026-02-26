//
//  HomeDatabase.swift
//  StorePass
//
//  Created by Lior Shor on 26/02/2026.
//

import Foundation
import SwiftData
import Dependencies

extension DependencyValues {
    var homeDatabase: HomeDatabase {
        get { self[HomeDatabase.self] }
        set { self[HomeDatabase.self] = newValue }
    }
}

struct HomeDatabase {
    var fetchAll: @MainActor @Sendable () throws -> [Home]
    var fetch: @MainActor @Sendable (FetchDescriptor<Home>) throws -> [Home]
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
                
                let descriptor = FetchDescriptor<Home>(sortBy: [SortDescriptor(\.createdAt)])
                return try homeContext.fetch(descriptor)
            } catch {
                return []
            }
        },
        fetch: { @MainActor descriptor in
            do {
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                return try homeContext.fetch(descriptor)
            } catch {
                return []
            }
        },
        add: { @MainActor model in
            do {
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                
                homeContext.insert(model)
            } catch {
                throw HomeError.add
            }
        },
        delete: { @MainActor model in
            do {
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                
                let modelToBeDelete = model
                homeContext.delete(modelToBeDelete)
            } catch {
                throw HomeError.delete
            }
        },
        update: { @MainActor model in
            do {
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                
                // SwiftData automatically tracks changes to model objects
                // We just need to ensure the context saves
                try homeContext.save()
            } catch {
                throw HomeError.update
            }
        },
        getDefaultHome: { @MainActor in
            do {
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                
                var descriptor = FetchDescriptor<Home>()
                descriptor.predicate = #Predicate { $0.isDefault == true }
                let homes = try homeContext.fetch(descriptor)
                return homes.first
            } catch {
                return nil
            }
        },
        setDefaultHome: { @MainActor home in
            do {
                @Dependency(\.databaseService.context) var context
                let homeContext = try context()
                
                // First, unset all other homes as default
                let descriptor = FetchDescriptor<Home>()
                let allHomes = try homeContext.fetch(descriptor)
                for existingHome in allHomes {
                    existingHome.isDefault = false
                }
                
                // Set the selected home as default
                home.isDefault = true
                home.updatedAt = Date()
                
                try homeContext.save()
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
        fetch: unimplemented("\(Self.self).fetch"),
        add: unimplemented("\(Self.self).add"),
        delete: unimplemented("\(Self.self).delete"),
        update: unimplemented("\(Self.self).update"),
        getDefaultHome: unimplemented("\(Self.self).getDefaultHome"),
        setDefaultHome: unimplemented("\(Self.self).setDefaultHome")
    )
    
    static let noop = Self(
        fetchAll: { [] },
        fetch: { _ in [] },
        add: { _ in },
        delete: { _ in },
        update: { _ in },
        getDefaultHome: { nil },
        setDefaultHome: { _ in }
    )
}
