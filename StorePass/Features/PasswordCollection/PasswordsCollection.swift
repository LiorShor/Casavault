//
//  DeviceCollectionFeature.swift
//  StorePass
//
//  Created by Lior Shor on 11/07/2025.
//

import Foundation
import ComposableArchitecture
import SwiftData

@Reducer
struct PasswordsCollection {
    @Dependency(\.passwordsUseCases) var passwordsUsecase
    
    @ObservableState
    struct State: Equatable {
        var passwords: [Password] = []
        
        init(passwords: [Password]) {
            self.passwords = passwords
        }
        
    }
    
    enum Action: Equatable {
        enum View: Equatable {
            case onPasswordTap(Password)
            case onDeletePassword(Password)
            case onAddPassword
        }
        
        @CasePathable
        enum Navigation: Equatable {
            case presentPassword(Password)
            case onAddPassword
        }
        
        case view(View)
        case navigation(Navigation)
        case itemsLoaded([Password])
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
                
            case .navigation:
                //                state.navigationPath.append(NavigationDestination.addPassword)
                return .none
//            case let .navigation(.onAddPassword):
//                //                return .send(.navigation(.onAddPassword))
                
            case let .itemsLoaded(passwords):
                state.passwords = passwords
                return .none
            }
        }
    }
    
    @MainActor
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAddPassword:
            return .send(.navigation(.onAddPassword))
            
        case let .onDeletePassword(password):
            return .run { @MainActor [password] send in
                await passwordsUsecase.removePassword(password)
                let updatedPasswords = await passwordsUsecase.fetchPasswords()
                send(.itemsLoaded(updatedPasswords))
            }
            
        case .onPasswordTap(let password):
            return .send(.navigation(.presentPassword(password)))
        }
    }
}

