//
//  PasswordDetail.swift
//  CasaVault
//
//  Created by Lior Shor on 05/02/2026.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import PhotosUI
import UIKit
import HomeKit

@Reducer
struct PasswordDetail {
    @Dependency(\.passwordsUseCases) var passwordsUsecase
    @Dependency(\.roomIconsService) var roomIconsService
    @Dependency(\.dismiss) var dismiss
    
    @ObservableState
    struct State: Equatable {
        var password: Password
        var isEditing: Bool = false
        var editedName: String
        var editedValue: String
        var editedRoom: String?
        var editedNotes: String
        var editedIcon: String?
        var availableRooms: [String] = []
        var pendingRoomDeletions: Set<String> = []

        var availableIcons: [String] {
            [
                "lightbulb.fill",
                "lock.fill",
                "fan.fill",
                "air.conditioner.horizontal.fill",
                "thermometer.medium",
                "speaker.wave.2.fill",
                "camera.fill",
                "tv.fill",
                "poweroutlet.type.h.square.fill",
                "switch.2",
                "sensor.fill",
                "window.ceiling.closed",
                "air.purifier.fill",
                "humidifier.fill",
                "door.garage.closed",
                "bell.fill",
                "heater.vertical.fill"
            ]
        }
        var isSaving: Bool = false
        var isDeleting: Bool = false
        
        @Presents var addRoomSheet: AddRoomSheet.State?
        @Presents var imageViewer: ImageViewer.State?
        
        var showingImageSourcePicker: Bool = false
        var pendingImageSourceType: UIImagePickerController.SourceType = .photoLibrary
        var showingImagePicker: Bool = false
        var attachmentsVersion: Int = 0
        
        // Validation
        var isValidPassword: Bool {
            let homeKitCodeRegex = /^\d{3}-\d{2}-\d{3}$/  // XXX-XX-XXX (8 digits)
            let matterCodeRegex = /^\d{4}-\d{3}-\d{4}$/   // XXXX-XXX-XXXX (11 digits)
            return editedValue.wholeMatch(of: homeKitCodeRegex) != nil || 
                   editedValue.wholeMatch(of: matterCodeRegex) != nil
        }
        
        var canSave: Bool {
            !editedName.isEmpty
        }
        
        init(password: Password) {
            self.password = password
            self.editedName = password.name
            self.editedValue = password.value
            self.editedRoom = password.room
            self.editedNotes = password.notes ?? ""
            self.editedIcon = password.icon
        }
    }
    
    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case onEditButtonTapped
            case onCancelButtonTapped
            case onSaveButtonTapped
            case onDeleteButtonTapped
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
            case imageSourcePickerCameraSelected
            case imageSourcePickerPhotoLibrarySelected
            case imageSourcePickerCancelled
            case imagePickerDismissed
            case imageSelected(Data)
            case iconChanged(String?)
            case scanQRCode
            case qrCodeScanned(String)
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
        case addRoomSheet(PresentationAction<AddRoomSheet.Action>)
        case imageViewer(PresentationAction<ImageViewer.Action>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
                
            case let .internal(internalAction):
                return reduceInternalAction(&state, internalAction)
                
            case let .addRoomSheet(.presented(.delegate(delegateAction))):
                return reduceAddRoomSheetDelegate(&state, delegateAction)
                
            case .addRoomSheet, .imageViewer, .delegate:
                return .none
            }
        }
        .ifLet(\.$addRoomSheet, action: \.addRoomSheet) {
            AddRoomSheet()
        }
        .ifLet(\.$imageViewer, action: \.imageViewer) {
            ImageViewer()
        }
    }
    
    @MainActor
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onEditButtonTapped:
            state.isEditing = true
            // If the current room was deleted, clear it from editing state
            if let currentRoom = state.password.room, state.pendingRoomDeletions.contains(currentRoom) {
                state.editedRoom = nil
            }
            // Initialize available rooms with current room if it exists and not deleted
            if let currentRoom = state.password.room, !state.pendingRoomDeletions.contains(currentRoom) {
                state.availableRooms = [currentRoom]
            }
            // Load available rooms only for the current home
            return .run { [homeId = state.password.homeId, pendingRoomDeletions = state.pendingRoomDeletions] send in
                let passwords: [Password]
                if let homeId = homeId {
                    passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                } else {
                    passwords = await passwordsUsecase.fetchPasswords()
                }
                let rooms = Set(passwords.compactMap { $0.room }).subtracting(pendingRoomDeletions).sorted()
                await send(.internal(.roomsLoaded(rooms)))
            }
            
        case .onCancelButtonTapped:
            state.isEditing = false
            state.editedName = state.password.name
            state.editedValue = state.password.value
            state.editedRoom = state.password.room
            state.editedNotes = state.password.notes ?? ""
            state.editedIcon = state.password.icon
            return .none

        case .onSaveButtonTapped:
            // Validate before saving
            guard state.canSave else {
                return .none
            }
            
            state.isSaving = true
            state.password.name = state.editedName
            state.password.value = state.editedValue
            state.password.room = state.editedRoom
            state.password.notes = state.editedNotes.isEmpty ? nil : state.editedNotes
            state.password.icon = state.editedIcon
            state.password.updatedAt = Date()
            
            let updatedPassword = state.password
            
            return .run { send in
                await passwordsUsecase.updatePassword(updatedPassword)
                await send(.internal(.passwordUpdated))
            }
            
        case .onDeleteButtonTapped:
            state.isDeleting = true
            let passwordToDelete = state.password
            return .run { send in
                await passwordsUsecase.removePassword(passwordToDelete)
                await dismiss()
            }
            
        case let .nameChanged(name):
            state.editedName = name
            return .none
            
        case let .valueChanged(value):
            // Auto-format the password with dashes as user types
            state.editedValue = formatPassword(value)
            return .none
            
        case let .roomSelected(room):
            state.editedRoom = room
            return .none
            
        case let .notesChanged(notes):
            state.editedNotes = notes
            return .none

        case let .iconChanged(icon):
            state.editedIcon = icon
            return .none
            
        case .addAttachmentTapped:
            state.showingImageSourcePicker = true
            return .none
            
        case .addAttachmentFromCamera:
            state.pendingImageSourceType = .camera
            state.showingImagePicker = true
            return .none
            
        case .addAttachmentFromLibrary:
            state.pendingImageSourceType = .photoLibrary
            state.showingImagePicker = true
            return .none
            
        case let .deleteAttachment(attachment):
            // In Core Data, attachments is a Set, not an Array
            if let attachments = state.password.attachments {
                state.password.attachments = attachments.filter { $0.id != attachment.id }
            }
            state.attachmentsVersion += 1
            return .none
            
        case let .viewAttachment(attachment):
            state.imageViewer = ImageViewer.State(attachment: attachment)
            return .none
            
        case .addNewRoomTapped:
            state.addRoomSheet = AddRoomSheet.State()
            return .none
            
        case .imageSourcePickerCameraSelected:
            state.pendingImageSourceType = .camera
            state.showingImageSourcePicker = false
            state.showingImagePicker = true
            return .none
            
        case .imageSourcePickerPhotoLibrarySelected:
            state.pendingImageSourceType = .photoLibrary
            state.showingImageSourcePicker = false
            state.showingImagePicker = true
            return .none
            
        case .imageSourcePickerCancelled:
            state.showingImageSourcePicker = false
            return .none
            
        case .imagePickerDismissed:
            state.showingImagePicker = false
            return .none
            
        case let .imageSelected(imageData):
            @Dependency(\.databaseService.context) var getContext
            do {
                let context = try getContext()
                let attachment = PasswordAttachment(context: context, imageData: imageData)
                attachment.password = state.password

                // In Core Data, attachments is a Set, not an Array
                if state.password.attachments == nil {
                    state.password.attachments = []
                }
                state.password.attachments?.insert(attachment)
                state.attachmentsVersion += 1
                state.showingImagePicker = false
            } catch {
                state.showingImagePicker = false
            }
            return .none
            
        case .scanQRCode:
            // This will be handled by the navigator - show QR scanner
            // For now, just a placeholder
            return .none
            
        case let .qrCodeScanned(payload):
            // Store the scanned QR code as the password value
            state.password.value = payload
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
    
    private func reduceAddRoomSheetDelegate(_ state: inout State, _ action: AddRoomSheet.Action.Delegate) -> Effect<Action> {
        switch action {
        case let .roomSaved(roomName, icon):
            state.editedRoom = roomName
            state.pendingRoomDeletions.remove(roomName)
            if !state.availableRooms.contains(roomName) {
                state.availableRooms.append(roomName)
                state.availableRooms.sort()
            }
            roomIconsService.setIcon(icon, roomName, state.password.homeId)
            roomIconsService.markRoomRestored(roomName, state.password.homeId)
            return .none
        }
    }
    
    // Format password with dashes as user types
    private func formatPassword(_ input: String) -> String {
        // Remove all non-digit characters
        let digits = input.filter { $0.isNumber }
        
        // Limit to 11 digits max
        let limitedDigits = String(digits.prefix(11))
        
        // Determine format based on length
        if limitedDigits.count <= 8 {
            // HomeKit format: XXX-XX-XXX (8 digits)
            var formatted = ""
            for (index, char) in limitedDigits.enumerated() {
                if index == 3 || index == 5 {
                    formatted.append("-")
                }
                formatted.append(char)
            }
            return formatted
        } else {
            // Matter format: XXXX-XXX-XXXX (11 digits)
            var formatted = ""
            for (index, char) in limitedDigits.enumerated() {
                if index == 4 || index == 7 {
                    formatted.append("-")
                }
                formatted.append(char)
            }
            return formatted
        }
    }
}
