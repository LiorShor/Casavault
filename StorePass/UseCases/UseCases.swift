//
//  UseCases.swift
//  CasaVault
//
//  Created by Lior Shor on 16/01/2026.
//

import Foundation
import Dependencies

struct UseCases: Sendable {
    let passwords: PasswordsUseCases
}

extension UseCases: DependencyKey {
    static let liveValue = UseCases(
        passwords: .liveValue
    )
    static let testValue = UseCases(
        passwords: .testValue
    )
}

extension DependencyValues {
    var useCases: UseCases {
        get { self[UseCases.self] }
        set { self[UseCases.self] = newValue }
    }
}
