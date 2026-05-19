//
//  DeviceCollectionFeature.swift
//  StorePass
//
//  Created by Lior Shor on 11/07/2025.
//

import Foundation
import CoreData
import ComposableArchitecture
import SwiftData
import SwiftUI

@Reducer
struct PasswordsCollection {
    @Dependency(\.passwordsUseCases) var passwordsUsecase
    @Dependency(\.homeUseCases) var homeUseCases
    
    @ObservableState
    struct State: Equatable {
        var passwords: [Password] = []
        var currentHomeId: UUID?
        var availableHomes: [Home] = []
        var viewMode: PasswordViewMode = .list
        var groupingMode: PasswordGroupingMode = .all
        var isEditMode: Bool = false
        var draggingPassword: Password?
        var searchText: String = ""
        
        var currentHome: Home? {
            availableHomes.first(where: { $0.id == currentHomeId })
        }
        
        var hasNoHome: Bool {
            currentHomeId == nil
        }
        
        // Filter passwords based on search text
        var filteredPasswords: [Password] {
            guard !searchText.isEmpty else {
                return passwords
            }
            
            return passwords.filter { password in
                password.name.localizedCaseInsensitiveContains(searchText) ||
                (password.room?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        init(passwords: [Password] = [], currentHomeId: UUID? = nil, availableHomes: [Home] = [], viewMode: PasswordViewMode = .list, groupingMode: PasswordGroupingMode = .all, searchText: String = "") {
            self.passwords = passwords
            self.currentHomeId = currentHomeId
            self.availableHomes = availableHomes
            self.viewMode = viewMode
            self.groupingMode = groupingMode
            self.searchText = searchText
        }
        
        // Computed property to get passwords grouped by room
        var groupedPasswords: [String: [Password]] {
            let passwordsToGroup = filteredPasswords
            
            guard groupingMode == .byRoom else {
                return ["All": passwordsToGroup]
            }
            
            var grouped: [String: [Password]] = [:]
            for password in passwordsToGroup {
                let roomName = password.room ?? String.localized(.noRoom)
                if grouped[roomName] == nil {
                    grouped[roomName] = []
                }
                grouped[roomName]?.append(password)
            }
            return grouped
        }
        
        // Get sorted room names
        var sortedRoomNames: [String] {
            let names = Array(groupedPasswords.keys).sorted()
            // Put "No Room" at the end
            if let noRoomKey = names.first(where: { $0 == String.localized(.noRoom) }) {
                return names.filter { $0 != noRoomKey } + [noRoomKey]
            }
            return names
        }
    }
    
    enum Action: Equatable {
        enum View: Equatable {
            case onPasswordTap(Password)
            case onDeletePassword(Password)
            case onAddPasswordButtonTapped
            case onImportFromHomeKitButtonTapped
            case onSettingsButtonTapped
            case toggleViewMode
            case groupingModeChanged(PasswordGroupingMode)
            case toggleEditMode
            case movePassword(IndexSet, Int, String) // indices, destination, roomName
            case gridMovePassword(Password, Password, String) // source, destination, roomName
            case startDragging(Password)
            case endDragging
            case onAppear
            case homeSelected(UUID)
            case searchTextChanged(String)
        }
        
        @CasePathable
        enum Navigation: Equatable {
            case presentPassword(Password)
            case onAddPassword
            case onImportFromHomeKit
            case presentSettings
            case navigateToHomes
        }
        
        case view(View)
        case navigation(Navigation)
        case itemsLoaded([Password])
        case defaultHomeLoaded(Home?)
        case homesLoaded([Home])
        case remoteStoreChanged
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
                
            case let .defaultHomeLoaded(home):
                state.currentHomeId = home?.id
                // Reload passwords for the new home
                if let homeId = home?.id {
                    return .run { @MainActor send in
                        let passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                        send(.itemsLoaded(passwords))
                    }
                } else {
                    // No default home, don't load passwords (screen will be locked)
                    return .none
                }
                
            case let .homesLoaded(homes):
                state.availableHomes = homes
                return .none

            case .remoteStoreChanged:
                let currentHomeId = state.currentHomeId
                return .run { @MainActor send in
                    let homes = await homeUseCases.fetchHomes()
                    send(.homesLoaded(homes))

                    if let homeId = currentHomeId {
                        let passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                        send(.itemsLoaded(passwords))
                    } else {
                        let defaultHome = await homeUseCases.getDefaultHome()
                        send(.defaultHomeLoaded(defaultHome))
                    }
                }
            }
        }
    }
    
    @MainActor
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            return .merge(
                .run { @MainActor send in
                    let homes = await homeUseCases.fetchHomes()
                    send(.homesLoaded(homes))

                    let defaultHome = await homeUseCases.getDefaultHome()
                    send(.defaultHomeLoaded(defaultHome))
                },
                .run { send in
                    for await _ in NotificationCenter.default.notifications(named: .NSPersistentStoreRemoteChange) {
                        await send(.remoteStoreChanged)
                    }
                }
                .cancellable(id: "PasswordsCollection.remoteChanges", cancelInFlight: true)
            )
            
        case let .homeSelected(homeId):
            state.currentHomeId = homeId
            // Reload passwords for the selected home
            return .run { @MainActor [homeId] send in
                let passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                send(.itemsLoaded(passwords))
            }
            
        case .onAddPasswordButtonTapped:
            return .send(.navigation(.onAddPassword))
            
        case .onImportFromHomeKitButtonTapped:
            return .send(.navigation(.onImportFromHomeKit))
            
        case let .onDeletePassword(password):
            return .run { @MainActor [password, currentHomeId = state.currentHomeId] send in
                await passwordsUsecase.removePassword(password)
                if let homeId = currentHomeId {
                    let updatedPasswords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                    send(.itemsLoaded(updatedPasswords))
                } else {
                    let updatedPasswords = await passwordsUsecase.fetchPasswords()
                    send(.itemsLoaded(updatedPasswords))
                }
            }
            
        case .onPasswordTap(let password):
            return .send(.navigation(.presentPassword(password)))
            
        case .onSettingsButtonTapped:
            return .send(.navigation(.presentSettings))
            
        case .toggleViewMode:
            state.viewMode = state.viewMode == .list ? .grid : .list
            UserDefaults.standard.set(state.viewMode.rawValue, forKey: "passwordViewMode")
            return .none
            
        case let .groupingModeChanged(mode):
            state.groupingMode = mode
            UserDefaults.standard.set(mode.rawValue, forKey: "passwordGroupingMode")
            return .none
            
        case .toggleEditMode:
            state.isEditMode.toggle()
            if !state.isEditMode {
                state.draggingPassword = nil
            }
            return .none
            
        case let .startDragging(password):
            state.draggingPassword = password
            return .none
            
        case .endDragging:
            state.draggingPassword = nil
            return .none
            
        case let .movePassword(indices, destination, roomName):
            var passwordsInRoom = state.groupedPasswords[roomName] ?? []
            passwordsInRoom.move(fromOffsets: indices, toOffset: destination)
            
            // Update all passwords in this room with new order (using updatedAt as order indicator)
            let baseTime = Date().timeIntervalSince1970
            for (index, password) in passwordsInRoom.enumerated() {
                password.updatedAt = Date(timeIntervalSince1970: baseTime + Double(index))
            }
            
            return .run { @MainActor [currentHomeId = state.currentHomeId] send in
                for password in passwordsInRoom {
                    await passwordsUsecase.updatePassword(password)
                }
                if let homeId = currentHomeId {
                    let updatedPasswords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                    send(.itemsLoaded(updatedPasswords))
                } else {
                    let updatedPasswords = await passwordsUsecase.fetchPasswords()
                    send(.itemsLoaded(updatedPasswords))
                }
            }
            
        case let .gridMovePassword(source, destination, roomName):
            var passwordsInRoom = state.groupedPasswords[roomName] ?? []
            
            guard let sourceIndex = passwordsInRoom.firstIndex(where: { $0.id == source.id }),
                  let destinationIndex = passwordsInRoom.firstIndex(where: { $0.id == destination.id }) else {
                return .none
            }
            
            // Move the password
            let movedPassword = passwordsInRoom.remove(at: sourceIndex)
            let newDestinationIndex = destinationIndex > sourceIndex ? destinationIndex : destinationIndex
            passwordsInRoom.insert(movedPassword, at: newDestinationIndex)
            
            // Update all passwords in this room with new order
            let baseTime = Date().timeIntervalSince1970
            for (index, password) in passwordsInRoom.enumerated() {
                password.updatedAt = Date(timeIntervalSince1970: baseTime + Double(index))
            }
            
            return .run { @MainActor [currentHomeId = state.currentHomeId] send in
                for password in passwordsInRoom {
                    await passwordsUsecase.updatePassword(password)
                }
                if let homeId = currentHomeId {
                    let updatedPasswords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                    send(.itemsLoaded(updatedPasswords))
                } else {
                    let updatedPasswords = await passwordsUsecase.fetchPasswords()
                    send(.itemsLoaded(updatedPasswords))
                }
            }
            
        case let .searchTextChanged(text):
            state.searchText = text
            return .none
        }
    }
}

