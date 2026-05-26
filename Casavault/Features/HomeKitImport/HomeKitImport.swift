//
//  HomeKitImport.swift
//  CasaVault
//
//  Created by Lior Shor on 06/02/2026.
//

import Foundation
import UIKit
import CoreData
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
        var isPermissionDenied: Bool = false
        var isImporting: Bool = false
        var existingPasswords: [Password] = []
        var currentHomeId: UUID?
        var currentHomeKitHomeId: UUID?
        @Presents var deleteConfirmation: DeleteConfirmationState?
        
        init() {}
        
        var areAllSelectableDevicesSelected: Bool {
            let selectable = devices.filter { hasPassword(for: $0) == nil }
            return !selectable.isEmpty && selectable.allSatisfy { selectedDeviceIds.contains($0.id) }
        }

        // Check if a device already has a password saved.
        // HomeKit UUIDs (uniqueIdentifier) change on every reinstall, so UUID match alone is not enough.
        // Falls back to name matching within the current home only — cross-home name matches are
        // intentionally ignored to avoid hiding devices that need to be imported into this home.
        func hasPassword(for device: HomeKitDevice) -> Password? {
            if let match = existingPasswords.first(where: { $0.homeKitUniqueIdentifier == device.uniqueIdentifier }) {
                return match
            }
            let byName = existingPasswords.filter { $0.name == device.name }
            return byName.first(where: { $0.homeId == currentHomeId })
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
            case openSettings
            case confirmDelete
            case cancelDelete
            case selectAllButtonTapped
        }
        
        @CasePathable
        enum Internal: Equatable {
            case devicesLoaded([HomeKitDevice])
            case loadingFailed(String)
            case permissionDenied
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
            state.isPermissionDenied = false

            return .merge(
                .run { send in
                    do {
                        print("📱 [HomeKitImport] onAppear - syncing HomeKit home IDs...")
                        // Refresh homeKitUniqueIdentifier for all stored homes before loading
                        // devices. After a reinstall the iCloud-restored UUID may no longer
                        // match the live HMHome UUID, causing fetchDevices(forHomeId:) to
                        // return nothing. importFromHomeKit() handles authorization and repairs
                        // stale UUIDs via name-matching — a no-op when already in sync.
                        _ = try await homeUseCases.importFromHomeKit()

                        print("🏠 [HomeKitImport] loading default home...")
                        let defaultHome = await homeUseCases.getDefaultHome()
                        print("🏠 [HomeKitImport] defaultHome: \(defaultHome?.name ?? "nil"), id: \(defaultHome?.id.uuidString ?? "nil"), homeKitId: \(defaultHome?.homeKitUniqueIdentifier?.uuidString ?? "nil")")
                        await send(.internal(.currentHomeLoaded(defaultHome)))

                        print("🔑 [HomeKitImport] fetching existing passwords...")
                        let existingPasswords = await passwordsUseCases.fetchPasswords()
                        print("🔑 [HomeKitImport] fetched \(existingPasswords.count) passwords:")
                        for p in existingPasswords {
                            print("  - '\(p.name)' | homeKitUID: \(p.homeKitUniqueIdentifier?.uuidString ?? "NIL") | homeId: \(p.homeId?.uuidString ?? "nil")")
                        }
                        await send(.internal(.existingPasswordsLoaded(existingPasswords)))

                        if let homeKitHomeId = defaultHome?.homeKitUniqueIdentifier {
                            print("📱 [HomeKitImport] fetching devices for homeKitHomeId: \(homeKitHomeId)")
                            let devices = try await homeKitService.fetchDevices(forHomeId: homeKitHomeId)
                            print("📱 [HomeKitImport] loaded \(devices.count) devices:")
                            for d in devices {
                                print("  - '\(d.name)' | uniqueIdentifier: \(d.uniqueIdentifier)")
                            }
                            await send(.internal(.devicesLoaded(devices)))
                        } else {
                            print("📱 [HomeKitImport] no homeKitHomeId - fetching ALL devices")
                            let devices = try await homeKitService.fetchDevices()
                            print("📱 [HomeKitImport] loaded \(devices.count) devices")
                            await send(.internal(.devicesLoaded(devices)))
                        }
                    } catch HomeKitError.permissionDenied {
                        await send(.internal(.permissionDenied))
                    } catch {
                        print("❌ [HomeKitImport] error: \(error)")
                        await send(.internal(.loadingFailed(error.localizedDescription)))
                    }
                },
                // Re-fetch passwords when CloudKit sync merges changes into the view context.
                // didMergeChangesObjectIDsNotification fires only on external merges
                // (not local saves), so it's precise for the post-reinstall sync case.
                .run { @MainActor send in
                    let context = CoreDataStack.shared.viewContext
                    for await _ in NotificationCenter.default.notifications(
                        named: NSManagedObjectContext.didMergeChangesObjectIDsNotification,
                        object: context
                    ) {
                        let passwords = await passwordsUseCases.fetchPasswords()
                        await send(.internal(.existingPasswordsLoaded(passwords)))
                    }
                }
                .cancellable(id: "HomeKitImport.cloudKitObserver", cancelInFlight: true)
            )
            
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
            if state.areAllSelectableDevicesSelected {
                let withoutPassword = state.devices.filter { state.hasPassword(for: $0) == nil }
                for device in withoutPassword {
                    state.selectedDeviceIds.remove(device.id)
                }
            } else {
                for device in state.devices where state.hasPassword(for: device) == nil {
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
                let existingPasswords = await passwordsUseCases.fetchPasswords()

                for device in selectedDevices {
                    // Match by homeKitUniqueIdentifier first; HomeKit UUIDs change on reinstall so
                    // fall back to name matching within the current home only. Cross-home matches are
                    // skipped so devices with the same name in another home get a fresh password here.
                    let byName = existingPasswords.filter { $0.name == device.name }
                    let matched = existingPasswords.first(where: { $0.homeKitUniqueIdentifier == device.uniqueIdentifier })
                        ?? byName.first(where: { $0.homeId == currentHomeId })

                    if let existingPassword = matched {
                        // Repair: set homeKitUniqueIdentifier if missing (legacy SwiftData passwords)
                        var needsSave = false
                        if existingPassword.homeKitUniqueIdentifier == nil {
                            existingPassword.homeKitUniqueIdentifier = device.uniqueIdentifier
                            needsSave = true
                        }
                        if existingPassword.room != device.roomName {
                            existingPassword.room = device.roomName
                            needsSave = true
                        }
                        if needsSave {
                            await passwordsUseCases.updatePassword(existingPassword)
                        }
                    } else {
                        @Dependency(\.databaseService.context) var getContext
                        let context = try getContext()
                        let iconName = await classifyDeviceIcon(deviceName: device.name)
                        let password = Password(
                            context: context,
                            name: device.name,
                            value: "",
                            room: device.roomName,
                            icon: iconName,
                            homeId: currentHomeId,
                            homeKitUniqueIdentifier: device.uniqueIdentifier
                        )
                        await passwordsUseCases.addPassword(password)
                    }
                }
                
                @Dependency(\.roomIconsService) var roomIconsService
                var classifiedRooms = Set<String>()
                for device in selectedDevices {
                    guard let roomName = device.roomName, !classifiedRooms.contains(roomName) else { continue }
                    classifiedRooms.insert(roomName)
                    let icon = await classifyRoomIcon(roomName: roomName)
                    roomIconsService.markRoomRestored(roomName, currentHomeId)
                    roomIconsService.addCustomRoom(roomName, currentHomeId)
                    roomIconsService.setIcon(icon, roomName, currentHomeId)
                }

                await send(.internal(.importCompleted))
            }
            
        case .cancelButtonTapped:
            return .run { _ in
                await dismiss()
            }
            
        case .retryButtonTapped:
            return .send(.view(.onAppear))

        case .openSettings:
            return .run { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    await MainActor.run { UIApplication.shared.open(url) }
                }
            }
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
            print("✅ [HomeKitImport] devicesLoaded: \(devices.count) devices, existingPasswords: \(state.existingPasswords.count)")
            for device in devices {
                if let match = state.hasPassword(for: device) {
                    print("  ✔ '\(device.name)' matched password '\(match.name)' (homeKitUID: \(match.homeKitUniqueIdentifier?.uuidString ?? "NIL"))")
                    state.selectedDeviceIds.insert(device.id)
                } else {
                    print("  ○ '\(device.name)' → no match (uid: \(device.uniqueIdentifier))")
                }
            }
            return .none
            
        case let .loadingFailed(error):
            state.isLoading = false
            state.loadingError = error
            return .none

        case .permissionDenied:
            state.isLoading = false
            state.isPermissionDenied = true
            return .none
            
        case let .existingPasswordsLoaded(passwords):
            state.existingPasswords = passwords
            print("🔄 [HomeKitImport] existingPasswordsLoaded: \(passwords.count) passwords, devices in state: \(state.devices.count)")
            for device in state.devices {
                if let match = state.hasPassword(for: device) {
                    print("  ✔ late-match '\(device.name)' → '\(match.name)'")
                    state.selectedDeviceIds.insert(device.id)
                }
            }
            return .none
            
        case .passwordDeleted:
            return .run { send in
                let existingPasswords = await passwordsUseCases.fetchPasswords()
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
