//
//  ManageRooms.swift
//  CasaVault
//

import Foundation
import ComposableArchitecture

@Reducer
struct ManageRooms {
    @Dependency(\.passwordsUseCases) var passwordsUsecase
    @Dependency(\.roomIconsService) var roomIconsService
    @Dependency(\.homeUseCases) var homeUseCases
    @Dependency(\.homeKitService) var homeKitService

    @ObservableState
    struct State: Equatable {
        var rooms: [String] = []
        var roomIcons: [String: String] = [:]
        var homeId: UUID?
        // Rooms deleted/renamed this session — filter them from Core Data re-fetches
        // because CloudKit may temporarily restore them via automaticallyMergesChangesFromParent.
        var pendingDeletions: Set<String> = []
        var loadedForHomeId: UUID? = nil
        var isImporting: Bool = false
        var isSyncing: Bool = false
        @Presents var renameSheet: RenameRoomSheet.State?
        @Presents var addRoomSheet: AddRoomSheet.State?
    }

    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case onAppear
            case deleteRoom(String)
            case renameTapped(String)
            case addRoomTapped
            case importFromHomeKitTapped
            case syncDeviceRoomsTapped
        }

        @CasePathable
        enum Internal: Equatable {
            case roomsLoaded([String])
            case importCompleted(importedRooms: Set<String>)
            case syncCompleted(restoredRooms: Set<String>)
        }

        case view(View)
        case `internal`(Internal)
        case renameSheet(PresentationAction<RenameRoomSheet.Action>)
        case addRoomSheet(PresentationAction<AddRoomSheet.Action>)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
            case let .internal(internalAction):
                return reduceInternalAction(&state, internalAction)
            case let .renameSheet(.presented(.delegate(.roomRenamed(oldName, newName, icon)))):
                return handleRename(&state, oldName: oldName, newName: newName, icon: icon)
            case .renameSheet:
                return .none
            case let .addRoomSheet(.presented(.delegate(.roomSaved(name, icon)))):
                return handleAddRoom(&state, name: name, icon: icon)
            case .addRoomSheet:
                return .none
            }
        }
        .ifLet(\.$renameSheet, action: \.renameSheet) {
            RenameRoomSheet()
        }
        .ifLet(\.$addRoomSheet, action: \.addRoomSheet) {
            AddRoomSheet()
        }
    }

    @MainActor
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            let homeId = state.homeId
            // When switching homes, clear the current list immediately and reload state for the new home.
            if homeId != state.loadedForHomeId {
                state.rooms = []
                state.roomIcons = [:]
                state.pendingDeletions = roomIconsService.getDeletedRooms(homeId)
            }
            return .run { @MainActor send in
                let rooms = await passwordsUsecase.fetchRoomsForHome(homeId)
                await send(.internal(.roomsLoaded(rooms)))
            }

        case let .deleteRoom(roomName):
            let homeId = state.homeId
            state.rooms.removeAll { $0 == roomName }
            state.roomIcons.removeValue(forKey: roomName)
            state.pendingDeletions.insert(roomName)
            roomIconsService.deleteRoom(roomName, homeId)
            roomIconsService.markRoomDeleted(roomName, homeId)
            roomIconsService.removeCustomRoom(roomName, homeId)
            return .run { @MainActor [homeId] send in
                await passwordsUsecase.deleteRoom(homeId, roomName)
            }

        case let .renameTapped(roomName):
            state.renameSheet = RenameRoomSheet.State(
                originalName: roomName,
                currentIcon: state.roomIcons[roomName]
            )
            return .none

        case .addRoomTapped:
            state.addRoomSheet = AddRoomSheet.State()
            return .none

        case .importFromHomeKitTapped:
            guard let homeId = state.homeId else { return .none }
            let existingRooms = Set(state.rooms)
            state.isImporting = true
            return .run { [homeId, existingRooms] send in
                let homes = await homeUseCases.fetchHomes()
                guard let home = homes.first(where: { $0.id == homeId }),
                      let homeKitId = home.homeKitUniqueIdentifier else {
                    await send(.internal(.importCompleted(importedRooms: [])))
                    return
                }

                let devices: [HomeKitDevice]
                do {
                    devices = try await homeKitService.fetchDevices(forHomeId: homeKitId)
                } catch {
                    await send(.internal(.importCompleted(importedRooms: [])))
                    return
                }

                // Collect unique room names from HomeKit that don't exist in the app yet
                let homeKitRooms = Set(devices.compactMap { $0.roomName })
                let newRooms = homeKitRooms.subtracting(existingRooms)

                // Register each new room and classify its icon
                for roomName in newRooms {
                    await MainActor.run {
                        roomIconsService.addCustomRoom(roomName, homeId)
                        roomIconsService.markRoomRestored(roomName, homeId)
                    }
                    let icon = await classifyRoomIcon(roomName: roomName)
                    await MainActor.run { roomIconsService.setIcon(icon, roomName, homeId) }
                }

                await send(.internal(.importCompleted(importedRooms: newRooms)))
            }

        case .syncDeviceRoomsTapped:
            guard let homeId = state.homeId else { return .none }
            let existingRooms = Set(state.rooms)
            state.isSyncing = true
            return .run { [homeId, existingRooms] send in
                let homes = await homeUseCases.fetchHomes()
                guard let home = homes.first(where: { $0.id == homeId }),
                      let homeKitId = home.homeKitUniqueIdentifier else {
                    await send(.internal(.syncCompleted(restoredRooms: [])))
                    return
                }

                let devices: [HomeKitDevice]
                do {
                    devices = try await homeKitService.fetchDevices(forHomeId: homeKitId)
                } catch {
                    await send(.internal(.syncCompleted(restoredRooms: [])))
                    return
                }

                // Build lookup maps: device UID → room, device name → room
                var deviceRoomByUID: [UUID: String] = [:]
                var deviceRoomByName: [String: String] = [:]
                for device in devices {
                    guard let room = device.roomName else { continue }
                    deviceRoomByUID[device.uniqueIdentifier] = room
                    if deviceRoomByName[device.name] == nil {
                        deviceRoomByName[device.name] = room
                    }
                }

                let passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)

                for password in passwords {
                    let matchedRoom: String?
                    if let uid = password.homeKitUniqueIdentifier {
                        matchedRoom = deviceRoomByUID[uid]
                    } else {
                        matchedRoom = deviceRoomByName[password.name]
                    }
                    guard let roomName = matchedRoom else { continue }
                    // Only update room assignments for rooms that already exist in the app.
                    // Deleted rooms (pendingDeletions) are intentionally excluded.
                    guard existingRooms.contains(roomName) else { continue }
                    guard password.room != roomName else { continue }
                    password.room = roomName
                    await passwordsUsecase.updatePassword(password)
                }

                await send(.internal(.syncCompleted(restoredRooms: [])))
            }
        }
    }

    @MainActor
    private func reduceInternalAction(_ state: inout State, _ action: Action.Internal) -> Effect<Action> {
        switch action {
        case let .roomsLoaded(rooms):
            state.loadedForHomeId = state.homeId
            // Filter out rooms that were deleted or renamed this session.
            // CloudKit's automaticallyMergesChangesFromParent can temporarily restore
            // deleted rooms before the local save has been exported to iCloud.
            let coreDataRooms = rooms.filter { !state.pendingDeletions.contains($0) }
            let customRooms = roomIconsService.getCustomRooms(state.homeId)
                .filter { !state.pendingDeletions.contains($0) }
            let allRooms = Array(Set(coreDataRooms).union(customRooms)).sorted()
            state.rooms = allRooms
            let homeId = state.homeId
            state.roomIcons = allRooms.reduce(into: [:]) { dict, room in
                if let icon = roomIconsService.getIcon(room, homeId) {
                    dict[room] = icon
                }
            }
            return .none

        case let .importCompleted(importedRooms):
            state.isImporting = false
            for room in importedRooms {
                state.pendingDeletions.remove(room)
            }
            return .send(.view(.onAppear))

        case let .syncCompleted(restoredRooms):
            state.isSyncing = false
            for room in restoredRooms {
                state.pendingDeletions.remove(room)
            }
            return .send(.view(.onAppear))
        }
    }

    @MainActor
    private func handleRename(_ state: inout State, oldName: String, newName: String, icon: String?) -> Effect<Action> {
        let homeId = state.homeId
        if let index = state.rooms.firstIndex(of: oldName) {
            state.rooms[index] = newName
            state.rooms.sort()
        }
        // Prevent CloudKit from restoring the old name via re-fetch.
        state.pendingDeletions.insert(oldName)
        roomIconsService.markRoomDeleted(oldName, homeId)
        roomIconsService.markRoomRestored(newName, homeId)
        roomIconsService.renameRoom(oldName, newName, homeId)
        // Keep custom rooms in sync with the rename
        let wasCustom = roomIconsService.getCustomRooms(homeId).contains(oldName)
        if wasCustom {
            roomIconsService.removeCustomRoom(oldName, homeId)
            roomIconsService.addCustomRoom(newName, homeId)
        }
        if let icon {
            roomIconsService.setIcon(icon, newName, homeId)
        }
        state.roomIcons.removeValue(forKey: oldName)
        if let icon {
            state.roomIcons[newName] = icon
        }
        return .run { @MainActor [homeId] send in
            await passwordsUsecase.renameRoom(homeId, oldName, newName)
        }
    }

    @MainActor
    private func handleAddRoom(_ state: inout State, name: String, icon: String?) -> Effect<Action> {
        let homeId = state.homeId
        roomIconsService.addCustomRoom(name, homeId)
        roomIconsService.markRoomRestored(name, homeId)
        state.pendingDeletions.remove(name)
        if let icon {
            roomIconsService.setIcon(icon, name, homeId)
            state.roomIcons[name] = icon
        }
        if !state.rooms.contains(name) {
            state.rooms.append(name)
            state.rooms.sort()
        }
        return .none
    }
}
