//
//  HomeKitImport.swift
//  StorePass
//
//  Created by Lior Shor on 06/02/2026.
//

import Foundation
import ComposableArchitecture
import HomeKit

@Reducer
struct HomeKitImport {
    @Dependency(\.homeKitService) var homeKitService
    @Dependency(\.passwordsUseCases) var passwordsUseCases
    @Dependency(\.homeUseCases) var homeUseCases
    @Dependency(\.dismiss) var dismiss
    
    @ObservableState
    struct State: Equatable {
        var devices: [HomeKitDevice] = []
        var selectedDeviceIds: Set<UUID> = []
        var isLoading: Bool = false
        var loadingError: String?
        var isImporting: Bool = false
        var existingPasswords: [Password] = []
        var currentHomeId: UUID?
        var currentHomeKitHomeId: UUID?
        @Presents var deleteConfirmation: DeleteConfirmationState?
        
        init() {}
        
        // Check if a device already has a password saved
        func hasPassword(for device: HomeKitDevice) -> Password? {
            return existingPasswords.first(where: { $0.homeKitUniqueIdentifier == device.uniqueIdentifier })
        }
    }
    
    struct DeleteConfirmationState: Equatable, Identifiable {
        let id = UUID()
        let device: HomeKitDevice
        let password: Password
    }
    
    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case onAppear
            case deviceToggled(UUID)
            case importButtonTapped
            case cancelButtonTapped
            case retryButtonTapped
            case confirmDelete
            case cancelDelete
            case selectAllButtonTapped
        }
        
        @CasePathable
        enum Internal: Equatable {
            case devicesLoaded([HomeKitDevice])
            case loadingFailed(String)
            case existingPasswordsLoaded([Password])
            case importCompleted
            case currentHomeLoaded(Home?)
            case passwordDeleted
        }
        
        case view(View)
        case `internal`(Internal)
        case deleteConfirmation(PresentationAction<Never>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
                
            case let .internal(internalAction):
                return reduceInternalAction(&state, internalAction)
                
            case .deleteConfirmation:
                return .none
            }
        }
        .ifLet(\.$deleteConfirmation, action: \.deleteConfirmation) {
            EmptyReducer()
        }
    }
    
    @MainActor
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            state.isLoading = true
            state.loadingError = nil
            
            return .run { send in
                do {
                    // Load current home first
                    let defaultHome = await homeUseCases.getDefaultHome()
                    await send(.internal(.currentHomeLoaded(defaultHome)))
                    
                    // Load existing passwords for the current home only
                    if let currentHomeId = defaultHome?.id {
                        let existingPasswords = await passwordsUseCases.fetchPasswordsForHome(currentHomeId)
                        await send(.internal(.existingPasswordsLoaded(existingPasswords)))
                    }
                    
                    // Request authorization
                    try await homeKitService.requestAuthorization()
                    
                    // Fetch devices for the specific home if available
                    if let homeKitHomeId = defaultHome?.homeKitUniqueIdentifier {
                        let devices = try await homeKitService.fetchDevices(forHomeId: homeKitHomeId)
                        await send(.internal(.devicesLoaded(devices)))
                    } else {
                        // No default home or not a HomeKit home, fetch all devices
                        let devices = try await homeKitService.fetchDevices()
                        await send(.internal(.devicesLoaded(devices)))
                    }
                } catch {
                    await send(.internal(.loadingFailed(error.localizedDescription)))
                }
            }
            
        case let .deviceToggled(deviceId):
            guard let device = state.devices.first(where: { $0.id == deviceId }) else {
                return .none
            }
            
            // Check if device is currently selected
            let isCurrentlySelected = state.selectedDeviceIds.contains(deviceId)
            
            // Check if device already has a password
            if let existingPassword = state.hasPassword(for: device) {
                // Device has password
                if isCurrentlySelected {
                    // Trying to uncheck - show delete confirmation
                    state.deleteConfirmation = DeleteConfirmationState(device: device, password: existingPassword)
                    return .none
                } else {
                    // Trying to check - just select it
                    state.selectedDeviceIds.insert(deviceId)
                    return .none
                }
            } else {
                // Device doesn't have password - toggle selection normally without confirmation
                if isCurrentlySelected {
                    state.selectedDeviceIds.remove(deviceId)
                } else {
                    state.selectedDeviceIds.insert(deviceId)
                }
                return .none
            }
            
        case .confirmDelete:
            guard let confirmation = state.deleteConfirmation else { return .none }
            let passwordToDelete = confirmation.password
            let deviceId = confirmation.device.id
            
            state.deleteConfirmation = nil
            state.selectedDeviceIds.remove(deviceId)
            
            return .run { [passwordToDelete] send in
                await passwordsUseCases.removePassword(passwordToDelete)
                await send(.internal(.passwordDeleted))
            }
            
        case .cancelDelete:
            state.deleteConfirmation = nil
            return .none
            
        case .selectAllButtonTapped:
            // Select all devices that don't have passwords (new devices only)
            for device in state.devices {
                if state.hasPassword(for: device) == nil {
                    state.selectedDeviceIds.insert(device.id)
                }
            }
            return .none
            
        case .importButtonTapped:
            guard !state.selectedDeviceIds.isEmpty else { return .none }
            guard let currentHomeId = state.currentHomeId else { return .none }
            
            state.isImporting = true
            let selectedDevices = state.devices.filter { state.selectedDeviceIds.contains($0.id) }
            
            return .run { send in
                // Fetch existing passwords only for the current home
                let existingPasswords = await passwordsUseCases.fetchPasswordsForHome(currentHomeId)
                
                for device in selectedDevices {
                    // Check if this device already exists in the current home (by HomeKit unique identifier)
                    if let existingPassword = existingPasswords.first(where: { $0.homeKitUniqueIdentifier == device.uniqueIdentifier }) {
                        // Update room if changed
                        if existingPassword.room != device.roomName {
                            existingPassword.room = device.roomName
                            existingPassword.updatedAt = Date()
                            await passwordsUseCases.updatePassword(existingPassword)
                        }
                    } else {
                        // Create new password for this device with explicit homeId
                        let password = Password(
                            name: device.name,
                            value: "", // Empty password - user needs to fill it in
                            room: device.roomName,
                            homeId: currentHomeId,
                            homeKitUniqueIdentifier: device.uniqueIdentifier
                        )
                        await passwordsUseCases.addPassword(password)
                    }
                }
                
                await send(.internal(.importCompleted))
            }
            
        case .cancelButtonTapped:
            return .run { _ in
                await dismiss()
            }
            
        case .retryButtonTapped:
            return .send(.view(.onAppear))
        }
    }
    
    @MainActor
    private func reduceInternalAction(_ state: inout State, _ action: Action.Internal) -> Effect<Action> {
        switch action {
        case let .currentHomeLoaded(home):
            state.currentHomeId = home?.id
            state.currentHomeKitHomeId = home?.homeKitUniqueIdentifier
            return .none
            
        case let .devicesLoaded(devices):
            state.isLoading = false
            state.devices = devices
            // Pre-select devices that already have passwords (after devices are loaded)
            for password in state.existingPasswords {
                if let homeKitId = password.homeKitUniqueIdentifier,
                   let device = devices.first(where: { $0.uniqueIdentifier == homeKitId }) {
                    state.selectedDeviceIds.insert(device.id)
                }
            }
            return .none
            
        case let .loadingFailed(error):
            state.isLoading = false
            state.loadingError = error
            return .none
            
        case let .existingPasswordsLoaded(passwords):
            state.existingPasswords = passwords
            return .none
            
        case .passwordDeleted:
            // Reload existing passwords after deletion
            guard let currentHomeId = state.currentHomeId else { return .none }
            return .run { send in
                let existingPasswords = await passwordsUseCases.fetchPasswordsForHome(currentHomeId)
                await send(.internal(.existingPasswordsLoaded(existingPasswords)))
            }
            
        case .importCompleted:
            state.isImporting = false
            return .run { _ in
                await dismiss()
            }
        }
    }
}
