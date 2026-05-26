//
//  PasswordDetailNavigator.swift
//  CasaVault
//
//  Created by Lior Shor on 27/02/2026.
//

import Foundation
import ComposableArchitecture
import UIKit

@Reducer
struct PasswordDetailNavigator {
    @Dependency(\.roomIconsService) var roomIconsService

    @ObservableState
    struct State: Equatable {
        var passwordDetail: PasswordDetail.State
        
        @Presents var addRoomSheet: AddRoomSheet.State?
        @Presents var imageViewer: ImageViewer.State?
        
        var showingImageSourcePicker: Bool = false
        var pendingImageSourceType: UIImagePickerController.SourceType = .photoLibrary
        var showingImagePicker: Bool = false
        var showingQRScanner: Bool = false
        
        init(password: Password, pendingRoomDeletions: Set<String> = []) {
            self.passwordDetail = PasswordDetail.State(password: password)
            self.passwordDetail.pendingRoomDeletions = pendingRoomDeletions
        }
    }
    
    enum Action: Equatable {
        case passwordDetail(PasswordDetail.Action)
        case addRoomSheet(PresentationAction<AddRoomSheet.Action>)
        case imageViewer(PresentationAction<ImageViewer.Action>)
        
        @CasePathable
        enum View: Equatable {
            case imageSourcePickerCameraSelected
            case imageSourcePickerPhotoLibrarySelected
            case imageSourcePickerCancelled
            case imagePickerDismissed
            case imageSelected(Data)
            case qrScannerDismissed
            case qrCodeScanned(String)
        }
        
        @CasePathable
        enum Delegate: Equatable {
            case passwordUpdated(Password)
        }
        
        case view(View)
        case delegate(Delegate)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.passwordDetail, action: \.passwordDetail) {
            PasswordDetail()
        }
        
        Reduce { state, action in
            switch action {
            case let .passwordDetail(.view(viewAction)):
                return reducePasswordDetailViewAction(&state, viewAction)
                
            case let .passwordDetail(.delegate(delegateAction)):
                return reducePasswordDetailDelegateAction(&state, delegateAction)
                
            case .passwordDetail:
                return .none
                
            case let .addRoomSheet(.presented(.delegate(delegateAction))):
                return reduceAddRoomSheetDelegate(&state, delegateAction)
                
            case .addRoomSheet:
                return .none
                
            case .imageViewer:
                return .none
                
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
                
            case .delegate:
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
    
    private func reducePasswordDetailViewAction(_ state: inout State, _ action: PasswordDetail.Action.View) -> Effect<Action> {
        switch action {
        case .addNewRoomTapped:
            state.addRoomSheet = AddRoomSheet.State()
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
            
        case let .viewAttachment(attachment):
            state.imageViewer = ImageViewer.State(attachment: attachment)
            return .none
            
        case .scanQRCode:
            state.showingQRScanner = true
            return .none
            
        default:
            return .none
        }
    }
    
    private func reducePasswordDetailDelegateAction(_ state: inout State, _ action: PasswordDetail.Action.Delegate) -> Effect<Action> {
        switch action {
        case let .passwordUpdated(password):
            return .run { send in
                await send(.delegate(.passwordUpdated(password)))
            }
        }
    }
    
    private func reduceAddRoomSheetDelegate(_ state: inout State, _ action: AddRoomSheet.Action.Delegate) -> Effect<Action> {
        switch action {
        case let .roomSaved(roomName, icon):
            state.passwordDetail.editedRoom = roomName
            if !state.passwordDetail.availableRooms.contains(roomName) {
                state.passwordDetail.availableRooms.append(roomName)
                state.passwordDetail.availableRooms.sort()
            }
            roomIconsService.setIcon(icon, roomName, state.passwordDetail.password.homeId)
            return .none
        }
    }
    
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
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
                attachment.password = state.passwordDetail.password

                if state.passwordDetail.password.attachments == nil {
                    state.passwordDetail.password.attachments = []
                }
                state.passwordDetail.password.attachments?.insert(attachment)
                state.passwordDetail.attachmentsVersion += 1
                state.showingImagePicker = false
            } catch {
                state.showingImagePicker = false
            }
            return .none
            
        case .qrScannerDismissed:
            state.showingQRScanner = false
            return .none
            
        case let .qrCodeScanned(payload):
            let digits = String.parseQRCode(payload)
            let limitedDigits = String(digits.prefix(11))
            var formatted = ""
            for (index, char) in limitedDigits.enumerated() {
                if limitedDigits.count <= 8 {
                    if index == 3 || index == 5 { formatted += "-" }
                } else {
                    if index == 4 || index == 7 { formatted += "-" }
                }
                formatted.append(char)
            }
            state.passwordDetail.editedValue = formatted
            state.showingQRScanner = false
            return .none
        }
    }
}
