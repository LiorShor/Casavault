//
//  HomeUseCases.swift
//  StorePass
//
//  Created by Lior Shor on 26/02/2026.
//

import Foundation
import Dependencies
import CoreData

struct HomeUseCases {
    var fetchHomes: () async -> [Home]
    var addHome: (Home) async -> Void
    var removeHome: (Home) async -> Void
    var updateHome: (Home) async -> Void
    var getDefaultHome: () async -> Home?
    var setDefaultHome: (Home) async -> Void
    var importFromHomeKit: () async -> [Home]
}

extension HomeUseCases: DependencyKey {
    static let liveValue = HomeUseCases(
        fetchHomes: {
            @Dependency(\.homeDatabase) var db
            do { return try db.fetchAll() }
            catch { return [] }
        },
        addHome: { home in
            @Dependency(\.homeDatabase) var db
            @Dependency(\.databaseService.context) var context
            do {
                // Home object should already be created with context
                return try db.add(home)
            }
            catch { }
        },
        removeHome: { home in
            @Dependency(\.homeDatabase) var db
            do {
                try db.delete(home)
            } catch { }
        },
        updateHome: { home in
            @Dependency(\.homeDatabase) var db
            do {
                try db.update(home)
            } catch { }
        },
        getDefaultHome: {
            @Dependency(\.homeDatabase) var db
            do {
                return try db.getDefaultHome()
            } catch {
                return nil
            }
        },
        setDefaultHome: { home in
            @Dependency(\.homeDatabase) var db
            do {
                try db.setDefaultHome(home)
            } catch { }
        },
        importFromHomeKit: {
            @Dependency(\.homeKitService) var homeKitService
            @Dependency(\.homeDatabase) var db
            
            do {
                // Request authorization first
                try await homeKitService.requestAuthorization()
                
                // Fetch HomeKit homes
                let homeKitHomes = try await homeKitService.fetchHomes()
                
                // Get existing homes to avoid duplicates
                let existingHomes = try db.fetchAll()
                let existingHomeKitIds = Set(existingHomes.compactMap { $0.homeKitUniqueIdentifier })
                
                // Get the context for creating new homes
                @Dependency(\.databaseService.context) var getContext
                let context = try getContext()
                
                // Create Home objects from HomeKit homes that don't exist yet
                var newHomes: [Home] = []
                for homeKitHome in homeKitHomes {
                    if !existingHomeKitIds.contains(homeKitHome.uniqueIdentifier) {
                        let home = Home(
                            context: context,
                            name: homeKitHome.name,
                            homeKitUniqueIdentifier: homeKitHome.uniqueIdentifier
                        )
                        try db.add(home)
                        newHomes.append(home)
                    }
                }
                
                return newHomes
            } catch {
                return []
            }
        }
    )
    
    static let testValue: HomeUseCases = .liveValue
}

extension DependencyValues {
    var homeUseCases: HomeUseCases {
        get { self[HomeUseCases.self] }
        set { self[HomeUseCases.self] = newValue }
    }
}
