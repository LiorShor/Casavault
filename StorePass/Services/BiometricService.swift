//
//  BiometricService.swift
//  StorePass
//

import Foundation
import LocalAuthentication
import Dependencies

struct BiometricService: Sendable {
    var authenticate: @Sendable (String) async -> Bool
    var biometricType: @Sendable () -> LABiometryType
    var canAuthenticate: @Sendable () -> Bool
}

extension BiometricService: DependencyKey {
    static let liveValue = BiometricService(
        authenticate: { reason in
            let context = LAContext()
            var error: NSError?
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                return false
            }
            do {
                return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            } catch {
                return false
            }
        },
        biometricType: {
            let context = LAContext()
            var error: NSError?
            context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            return context.biometryType
        },
        canAuthenticate: {
            let context = LAContext()
            var error: NSError?
            return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        }
    )

    static let testValue = BiometricService(
        authenticate: { _ in true },
        biometricType: { .faceID },
        canAuthenticate: { true }
    )
}

extension DependencyValues {
    var biometricService: BiometricService {
        get { self[BiometricService.self] }
        set { self[BiometricService.self] = newValue }
    }
}
