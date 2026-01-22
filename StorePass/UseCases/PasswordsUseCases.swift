//
//  PasswordsUseCases.swift
//  StorePass
//
//  Created by Lior Shor on 16/01/2026.
//

import Foundation
import Dependencies
import SwiftData

struct PasswordsUseCases {
    var fetchPasswords: () async -> [Password]
    var addPassword: (Password) async -> Void
    var removePassword: (Password) async -> Void
}

extension PasswordsUseCases: DependencyKey {
    static let liveValue = PasswordsUseCases(
        fetchPasswords: {
            @Dependency(\.swiftData) var db
            do { return try db.fetchAll() }
                catch { return [] }
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
