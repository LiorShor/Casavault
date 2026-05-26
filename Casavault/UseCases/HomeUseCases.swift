//
//  HomeUseCases.swift
//  CasaVault
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
    var importFromHomeKit: () async throws -> [Home]
}

extension HomeUseCases: DependencyKey {
    static let liveValue = HomeUseCases(
        fetchHomes: {
            @Dependency(\.homeDatabase) var db
            return (try? await MainActor.run { try db.fetchAll() }) ?? []
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
                // HomeKit operations run on background thread
                try await homeKitService.requestAuthorization()
                let homeKitHomes = try await homeKitService.fetchHomes()

                // All Core Data operations must run on the main actor (viewContext is main-thread only)
                return try await MainActor.run {
                    let existingHomes = try db.fetchAll()
                    let existingHomeKitIds = Set(existingHomes.compactMap { $0.homeKitUniqueIdentifier })

                    @Dependency(\.databaseService.context) var getContext
                    let context = try getContext()

                    var newHomes: [Home] = []
                    for homeKitHome in homeKitHomes {
                        if existingHomeKitIds.contains(homeKitHome.uniqueIdentifier) {
                            continue
                        }
                        // Update any home with matching name (with or without a homeKitId).
                        // This handles reinstalls and cross-iCloud-account scenarios where the
                        // stored UUID no longer matches the current HomeKit home's UUID.
                        if let existingHome = existingHomes.first(where: {
                            $0.name.lowercased() == homeKitHome.name.lowercased()
                        }) {
                            existingHome.homeKitUniqueIdentifier = homeKitHome.uniqueIdentifier
                            try db.update(existingHome)
                            continue
                        }
                        let home = Home(
                            context: context,
                            name: homeKitHome.name,
                            homeKitUniqueIdentifier: homeKitHome.uniqueIdentifier
                        )
                        try db.add(home)
                        newHomes.append(home)
                    }
                    return newHomes
                }
            } catch HomeKitError.permissionDenied {
                throw HomeKitError.permissionDenied
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
