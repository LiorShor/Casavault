//
//  PasswordsNavigator.swift
//  StorePass
//
//  Created by Lior Shor on 15/01/2026.
//

import Foundation
import ComposableArchitecture

@Reducer
struct PasswordsNavigator {
    @Dependency(\.passwordsUseCases) var passwordsUsecase
    
    @ObservableState
    struct State: Equatable {
        var passwordsCollection = PasswordsCollection.State(passwords: [])
        @Presents var insertPassword: InsertPassword.State?
        @Presents var passwordDetail: Password?
        
        init() {}
    }
    
    enum Action {
        case onAppear
        case passwordsCollection(PasswordsCollection.Action)
        case insertPassword(PresentationAction<InsertPassword.Action>)
        case passwordDetail(PresentationAction<Never>)
        case passwordsLoaded([Password])
    }
    
    init() {}
    
    var body: some Reducer<State, Action> {
        Scope(state: \.passwordsCollection, action: \.passwordsCollection) {
            PasswordsCollection()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let passwords = await passwordsUsecase.fetchPasswords()
                    await send(.passwordsLoaded(passwords))
                }
                
            case let .passwordsLoaded(passwords):
                state.passwordsCollection.passwords = passwords
                return .none
                
            case .passwordsCollection(.navigation(.onAddPassword)):
                state.insertPassword = InsertPassword.State()
                return .none
                
            case let .passwordsCollection(.navigation(.presentPassword(password))):
                state.passwordDetail = password
                return .none
                
            case .insertPassword(.dismiss):
                // Reload passwords after dismissing insert sheet
                return .run { send in
                    let passwords = await passwordsUsecase.fetchPasswords()
                    await send(.passwordsLoaded(passwords))
                }
                
            case .passwordsCollection, .insertPassword, .passwordDetail:
                return .none
            }
        }
        .ifLet(\.$insertPassword, action: \.insertPassword) {
            InsertPassword()
        }
        .ifLet(\.$passwordDetail, action: \.passwordDetail) {
            EmptyReducer()
        }
    }
}

extension PasswordsNavigator {
}
