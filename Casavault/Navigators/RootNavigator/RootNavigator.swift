//
//  RootNavigator.swift
//  CasaVault
//
//  Created by Lior Shor on 15/01/2026.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@MainActor
@Reducer
struct RootNavigator {
    @Dependency(\.biometricService) var biometricService

    @ObservableState
    struct State: Equatable {
        var destination: Destination.State
        var isLocked: Bool = false
        var shouldLockOnForeground: Bool = false

        init(destination: Destination.State? = nil) {
            self.destination = destination ?? .splash(Splash.State())
        }
    }

    enum Action {
        case destination(Destination.Action)
        case scenePhaseChanged(ScenePhase)
        case unlockTapped
        case authenticationCompleted(Bool)
    }

    public init() {}

    var body: some Reducer<State, Action> {
        Scope(state: \.destination, action: \.destination, child: Destination.init)

        Reduce { state, action in
            switch action {
            case .destination(.splash(.navigation(.splashCompleted))):
                state.destination = .home(HomeNavigator.State())
                if UserDefaults.standard.bool(forKey: "isBiometricLockEnabled") {
                    state.isLocked = true
                    return .send(.unlockTapped)
                }
                return .none

            case let .scenePhaseChanged(phase):
                switch phase {
                case .background:
                    if UserDefaults.standard.bool(forKey: "isBiometricLockEnabled") {
                        state.shouldLockOnForeground = true
                    }
                case .active:
                    if state.shouldLockOnForeground {
                        state.shouldLockOnForeground = false
                        state.isLocked = true
                        return .send(.unlockTapped)
                    }
                default:
                    break
                }
                return .none

            case .unlockTapped:
                guard state.isLocked else { return .none }
                return .run { send in
                    let reason = String.localized(.biometricLockReason)
                    let success = await biometricService.authenticate(reason)
                    await send(.authenticationCompleted(success))
                }

            case let .authenticationCompleted(success):
                if success {
                    state.isLocked = false
                }
                return .none

            case .destination:
                return .none
            }
        }
    }
}

extension RootNavigator {
    
    @Reducer
    struct Destination {
        @ObservableState
        enum State: Equatable {
            case splash(Splash.State)
            case home(HomeNavigator.State)
        }
        
        enum Action {
            case splash(Splash.Action)
            case home(HomeNavigator.Action)
        }
        
        var body: some Reducer<State, Action> {
            Scope(state: \.splash, action: \.splash, child: Splash.init)
            Scope(state: \.home, action: \.home, child: HomeNavigator.init)
        }
    }
}
