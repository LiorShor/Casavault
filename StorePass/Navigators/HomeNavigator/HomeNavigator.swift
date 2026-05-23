//
//  HomeNavigator.swift
//  StorePass
//
//  Created by Lior Shor on 15/01/2026.
//

import Foundation
import ComposableArchitecture

@MainActor
@Reducer
struct HomeNavigator {

    @ObservableState
    struct State: Equatable {
        var selectedTab: TabType = .passwords

        var passwords = PasswordsNavigator.State()
        var homes = HomesNavigator.State()
        var rooms = ManageRooms.State()

        init(selectedTab: TabType = .passwords) {
            self.selectedTab = selectedTab
        }
    }

    enum Action {
        case onTabSelection(TabType)
        case passwords(PasswordsNavigator.Action)
        case homes(HomesNavigator.Action)
        case rooms(ManageRooms.Action)
    }

    init() {}

    var body: some Reducer<State, Action> {

        Scope(state: \.passwords, action: \.passwords, child: PasswordsNavigator.init)
        Scope(state: \.homes, action: \.homes, child: HomesNavigator.init)
        Scope(state: \.rooms, action: \.rooms, child: ManageRooms.init)

        Reduce { state, action in
            switch action {
            case let .onTabSelection(tab):
                state.selectedTab = tab
                return .none

            case .passwords(.delegate(.navigateToHomes)):
                state.selectedTab = .homes
                return .none

            case .passwords(.passwordsCollection(.defaultHomeLoaded(_))):
                state.rooms.homeId = state.passwords.passwordsCollection.currentHomeId
                return .none

            case .passwords(.passwordsCollection(.view(.homeSelected(_)))):
                state.rooms.homeId = state.passwords.passwordsCollection.currentHomeId
                return .none

            case let .homes(.homesCollection(.view(.toggleDefaultHome(home)))):
                state.rooms.homeId = home.id
                return .none

            case let .rooms(.`internal`(.importCompleted(importedRooms: importedRooms))):
                for room in importedRooms {
                    state.passwords.passwordsCollection.pendingRoomDeletions.remove(room)
                }
                guard !importedRooms.isEmpty else { return .none }
                return .send(.passwords(.passwordsCollection(.remoteStoreChanged)))

            case let .rooms(.`internal`(.syncCompleted(restoredRooms: restoredRooms))):
                print("[HomeNavigator] syncCompleted: restoredRooms=\(restoredRooms)")
                print("[HomeNavigator] pendingRoomDeletions before=\(state.passwords.passwordsCollection.pendingRoomDeletions)")
                for room in restoredRooms {
                    state.passwords.passwordsCollection.pendingRoomDeletions.remove(room)
                }
                print("[HomeNavigator] pendingRoomDeletions after=\(state.passwords.passwordsCollection.pendingRoomDeletions)")
                guard !restoredRooms.isEmpty else { return .none }
                return .send(.passwords(.passwordsCollection(.remoteStoreChanged)))

            case let .rooms(.view(.deleteRoom(roomName))):
                state.passwords.passwordsCollection.pendingRoomDeletions.insert(roomName)
                if state.passwords.passwordsCollection.selectedFilter == .room(roomName) {
                    state.passwords.passwordsCollection.selectedFilter = nil
                }
                state.passwords.passwordDetailNavigator?.passwordDetail.pendingRoomDeletions.insert(roomName)
                return .none

            case let .rooms(.renameSheet(.presented(.delegate(.roomRenamed(oldName, _, _))))):
                state.passwords.passwordsCollection.pendingRoomDeletions.insert(oldName)
                if state.passwords.passwordsCollection.selectedFilter == .room(oldName) {
                    state.passwords.passwordsCollection.selectedFilter = nil
                }
                state.passwords.passwordDetailNavigator?.passwordDetail.pendingRoomDeletions.insert(oldName)
                return .none

            case .passwords, .homes, .rooms:
                return .none
            }
        }
    }
}

extension HomeNavigator {

    enum TabType {
        case passwords
        case homes
        case rooms
    }
}
