//
//  DataBase.swift
//  StorePass
//
//  Created by Lior Shor on 16/01/2026.
//

import Foundation
import SwiftData
import Dependencies

extension DependencyValues {
    var databaseService: Database {
        get { self[Database.self] }
        set { self[Database.self] = newValue }
    }
}

struct Database {
    private static let sharedContext: ModelContext = {
        do {
            let url = URL.applicationSupportDirectory.appending(path: "Model.sqlite")
            let config = ModelConfiguration(url: url)
            let container = try ModelContainer(for: Password.self, configurations: config)
            return ModelContext(container)
        } catch {
            fatalError("Failed to create container")
        }
    }()
    
    var context: () throws -> ModelContext
}

extension Database: DependencyKey {
    @MainActor
    public static let liveValue = Self(
        context: { sharedContext }
    )
}

extension Database: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        context: unimplemented("\(Self.self).context")
    )
    
    static let noop = Self(
        context: unimplemented("\(Self.self).context")
    )
}
