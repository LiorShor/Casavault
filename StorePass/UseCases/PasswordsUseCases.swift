//
//  PasswordsUseCases.swift
//  StorePass
//
//  Created by Lior Shor on 16/01/2026.
//

import Foundation
import Dependencies
import CoreData

struct PasswordsUseCases {
    var fetchPasswords: () async -> [Password]
    var fetchPasswordsForHome: (UUID) async -> [Password]
    var addPassword: (Password) async -> Void
    var removePassword: (Password) async -> Void
    var updatePassword: (Password) async -> Void
    var fetchRoomsForHome: (UUID?) async -> [String]
    var renameRoom: (UUID?, String, String) async -> Void
    var deleteRoom: (UUID?, String) async -> Void
}

extension PasswordsUseCases: DependencyKey {
    static let liveValue = PasswordsUseCases(
        fetchPasswords: {
            @Dependency(\.swiftData) var db
            do { return try db.fetchAll() }
                catch { return [] }
            },
        fetchPasswordsForHome: { homeId in
            @Dependency(\.databaseService.context) var getContext
            do {
                let context = try getContext()
                let fetchRequest: NSFetchRequest<Password> = NSFetchRequest(entityName: "Password")
                fetchRequest.predicate = NSPredicate(format: "homeId == %@", homeId as CVarArg)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                return try context.fetch(fetchRequest)
            } catch {
                return []
            }
        },
        addPassword: { password in
            @Dependency(\.swiftData) var db
            do { return try db.add(password) }
            catch {
                
            }
        },
        removePassword: { password in
            @Dependency(\.swiftData) var db
            do { 
                try db.delete(password)
            } catch {
                // Handle error if needed
            }
        },
        updatePassword: { password in
            @Dependency(\.swiftData) var db
            do {
                try db.update(password)
            } catch {
                // Handle error if needed
            }
        },
        fetchRoomsForHome: { homeId in
            @Dependency(\.databaseService.context) var getContext
            guard let context = try? getContext() else { return [] }
            let fetchRequest: NSFetchRequest<Password> = NSFetchRequest(entityName: "Password")
            if let homeId {
                fetchRequest.predicate = NSPredicate(format: "homeId == %@", homeId as CVarArg)
            }
            let passwords = (try? context.fetch(fetchRequest)) ?? []
            return Array(Set(passwords.compactMap { $0.room })).sorted()
        },
        renameRoom: { homeId, oldName, newName in
            @Dependency(\.databaseService) var database
            @Dependency(\.databaseService.context) var getContext
            guard let context = try? getContext() else { return }
            let fetchRequest: NSFetchRequest<Password> = NSFetchRequest(entityName: "Password")
            var predicates: [NSPredicate] = [NSPredicate(format: "room == %@", oldName)]
            if let homeId {
                predicates.append(NSPredicate(format: "homeId == %@", homeId as CVarArg))
            }
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            let passwords = (try? context.fetch(fetchRequest)) ?? []
            for password in passwords {
                password.room = newName
            }
            try? database.saveContext()
        },
        deleteRoom: { homeId, roomName in
            @Dependency(\.databaseService) var database
            @Dependency(\.databaseService.context) var getContext
            guard let context = try? getContext() else { return }
            let fetchRequest: NSFetchRequest<Password> = NSFetchRequest(entityName: "Password")
            var predicates: [NSPredicate] = [NSPredicate(format: "room == %@", roomName)]
            if let homeId {
                predicates.append(NSPredicate(format: "homeId == %@", homeId as CVarArg))
            }
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            let passwords = (try? context.fetch(fetchRequest)) ?? []
            for password in passwords {
                password.room = nil
            }
            try? database.saveContext()
        }
    )

    static let testValue: PasswordsUseCases = .liveValue
}

extension DependencyValues {
    var passwordsUseCases: PasswordsUseCases {
        get { self[PasswordsUseCases.self] }
        set { self[PasswordsUseCases.self] = newValue }
    }
}

//struct OpenAppSettingsUseCase {
//    var openAppSettings: () async -> Void
//}
//
//extension OpenAppSettingsUseCase: DependencyKey {
//    static let liveValue = OpenAppSettingsUseCase(
//        openAppSettings: {
//            @Dependency(\.openURL) var openURL
//            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
//            await openURL(url)
//        }
//    )
//    
//    static let testValue = OpenAppSettingsUseCase(
//        openAppSettings: liveValue.openAppSettings
//    )
//}
//
//extension DependencyValues {
//    var openAppSettings: () async -> Void {
//        get { self[OpenAppSettingsUseCase.self].openAppSettings }
//        set { self[OpenAppSettingsUseCase.self].openAppSettings = newValue }
//    }
//}
