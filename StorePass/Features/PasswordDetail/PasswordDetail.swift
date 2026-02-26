//
//  PasswordDetail.swift
//  StorePass
//
//  Created by Lior Shor on 05/02/2026.
//

import Foundation
import ComposableArchitecture

@Reducer
struct PasswordDetail {
    @Dependency(\.passwordsUseCases) var passwordsUsecase
    @Dependency(\.dismiss) var dismiss
    
    @ObservableState
    struct State: Equatable {
        var password: Password
        var isEditing: Bool = false
        var editedName: String
        var editedValue: String
        var isSaving: Bool = false
        
        init(password: Password) {
            self.password = password
            self.editedName = password.name
            self.editedValue = password.value
        }
    }
    
    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case onEditButtonTapped
            case onCancelButtonTapped
            case onSaveButtonTapped
            case nameChanged(String)
            case valueChanged(String)
        }
        
        @CasePathable
        enum Internal: Equatable {
            case passwordUpdated
        }
        
        @CasePathable
        enum Delegate: Equatable {
            case passwordUpdated(Password)
        }
        
        case view(View)
        case `internal`(Internal)
        case delegate(Delegate)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
                
            case let .internal(internalAction):
                return reduceInternalAction(&state, internalAction)
                
            case .delegate:
                return .none
            }
        }
    }
    
    @MainActor
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onEditButtonTapped:
            state.isEditing = true
            return .none
            
        case .onCancelButtonTapped:
            state.isEditing = false
            state.editedName = state.password.name
            state.editedValue = state.password.value
            return .none
            
        case .onSaveButtonTapped:
            guard !state.editedName.isEmpty else {
                return .none
            }
            
            state.isSaving = true
            state.password.name = state.editedName
            state.password.value = state.editedValue
            state.password.updatedAt = Date()
            
            let updatedPassword = state.password
            
            return .run { send in
                await passwordsUsecase.updatePassword(updatedPassword)
                await send(.internal(.passwordUpdated))
            }
            
        case let .nameChanged(name):
            state.editedName = name
            return .none
            
        case let .valueChanged(value):
            state.editedValue = value
            return .none
        }
    }
    
    @MainActor
    private func reduceInternalAction(_ state: inout State, _ action: Action.Internal) -> Effect<Action> {
        switch action {
        case .passwordUpdated:
            state.isSaving = false
            state.isEditing = false
            return .run { [password = state.password] send in
                await send(.delegate(.passwordUpdated(password)))
            }
        }
    }
}
