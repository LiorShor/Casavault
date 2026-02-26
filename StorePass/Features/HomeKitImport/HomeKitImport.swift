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
        var existingPasswordNames: Set<String> = []
        var currentHomeId: UUID?
        var currentHomeKitHomeId: UUID?
        
        init() {}
        
        // Check if a device already has a password saved
        func hasPassword(for device: HomeKitDevice) -> Bool {
            return existingPasswordNames.contains(device.name)
        }
    }
    
    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case onAppear
            case deviceToggled(UUID)
            case importButtonTapped
            case cancelButtonTapped
            case retryButtonTapped
        }
        
        @CasePathable
        enum Internal: Equatable {
            case devicesLoaded([HomeKitDevice])
            case loadingFailed(String)
            case existingPasswordsLoaded([Password])
            case importCompleted
            case currentHomeLoaded(Home?)
        }
        
        case view(View)
        case `internal`(Internal)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
                
            case let .internal(internalAction):
                return reduceInternalAction(&state, internalAction)
            }
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
                    
                    // Load existing passwords first
                    let existingPasswords = await passwordsUseCases.fetchPasswords()
                    await send(.internal(.existingPasswordsLoaded(existingPasswords)))
                    
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
            if state.selectedDeviceIds.contains(deviceId) {
                state.selectedDeviceIds.remove(deviceId)
            } else {
                state.selectedDeviceIds.insert(deviceId)
            }
            return .none
            
        case .importButtonTapped:
            guard !state.selectedDeviceIds.isEmpty else { return .none }
            
            state.isImporting = true
            let selectedDevices = state.devices.filter { state.selectedDeviceIds.contains($0.id) }
            let currentHomeId = state.currentHomeId
            
            return .run { send in
                // Fetch existing passwords to check for HomeKit synced devices
                let existingPasswords = await passwordsUseCases.fetchPasswords()
                
                for device in selectedDevices {
                    // Check if this device already exists (by HomeKit unique identifier)
                    if let existingPassword = existingPasswords.first(where: { $0.homeKitUniqueIdentifier == device.uniqueIdentifier }) {
                        // Update room if changed
                        if existingPassword.room != device.roomName {
                            existingPassword.room = device.roomName
                            existingPassword.updatedAt = Date()
                            await passwordsUseCases.updatePassword(existingPassword)
                        }
                    } else {
                        // Create new password for this device
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
            return .none
            
        case let .loadingFailed(error):
            state.isLoading = false
            state.loadingError = error
            return .none
            
        case let .existingPasswordsLoaded(passwords):
            state.existingPasswordNames = Set(passwords.map { $0.name })
            return .none
            
        case .importCompleted:
            state.isImporting = false
            return .run { _ in
                await dismiss()
            }
        }
    }
}
