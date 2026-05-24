//
//  SplashInteractor.swift
//  CasaVault
//
//  Created by Lior Shor on 15/01/2026.
//

import Foundation
import Dependencies

struct SplashInteractor: Sendable {
    @Dependency(\.useCases.passwords) private var passwords

    func fetchPasswords() async -> [Password] {
        await passwords.fetchPasswords()
    }
}

extension SplashInteractor: DependencyKey {
    static let liveValue = SplashInteractor()
    static let testValue = SplashInteractor()
}
