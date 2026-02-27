//
//  PasswordDetail.swift
//  StorePass
//
//  Created by Lior Shor on 05/02/2026.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import PhotosUI

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
        var editedRoom: String?
        var editedNotes: String
        var availableRooms: [String] = []
        var isSaving: Bool = false
        
        init(password: Password) {
            self.password = password
            self.editedName = password.name
            self.editedValue = password.value
            self.editedRoom = password.room
            self.editedNotes = password.notes ?? ""
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
            case roomSelected(String?)
            case notesChanged(String)
            case addNewRoomTapped
            case addAttachmentTapped
            case addAttachmentFromCamera
            case addAttachmentFromLibrary
            case deleteAttachment(PasswordAttachment)
            case viewAttachment(PasswordAttachment)
        }
        
        @CasePathable
        enum Internal: Equatable {
            case passwordUpdated
            case roomsLoaded([String])
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
            // Initialize available rooms with current room if it exists
            if let currentRoom = state.password.room {
                state.availableRooms = [currentRoom]
            }
            // Load available rooms only for the current home
            return .run { [homeId = state.password.homeId] send in
                let passwords: [Password]
                if let homeId = homeId {
                    passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                } else {
                    passwords = await passwordsUsecase.fetchPasswords()
                }
                let rooms = Set(passwords.compactMap { $0.room }).sorted()
                await send(.internal(.roomsLoaded(rooms)))
            }
            
        case .onCancelButtonTapped:
            state.isEditing = false
            state.editedName = state.password.name
            state.editedValue = state.password.value
            state.editedRoom = state.password.room
            state.editedNotes = state.password.notes ?? ""
            return .none
            
        case .onSaveButtonTapped:
            guard !state.editedName.isEmpty else {
                return .none
            }
            
            state.isSaving = true
            state.password.name = state.editedName
            state.password.value = state.editedValue
            state.password.room = state.editedRoom
            state.password.notes = state.editedNotes.isEmpty ? nil : state.editedNotes
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
            
        case let .roomSelected(room):
            state.editedRoom = room
            return .none
            
        case let .notesChanged(notes):
            state.editedNotes = notes
            return .none
            
        case .addAttachmentTapped:
            // Handled by navigator
            return .none
            
        case .addAttachmentFromCamera:
            // Handled by navigator
            return .none
            
        case .addAttachmentFromLibrary:
            // Handled by navigator
            return .none
            
        case let .deleteAttachment(attachment):
            state.password.attachments?.removeAll(where: { $0.id == attachment.id })
            return .none
            
        case .viewAttachment:
            // Handled by navigator
            return .none
            
        case .addNewRoomTapped:
            // Handled by navigator
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
            
        case let .roomsLoaded(rooms):
            state.availableRooms = rooms
            return .none
        }
    }
}
