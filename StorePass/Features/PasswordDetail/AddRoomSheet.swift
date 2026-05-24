//
//  AddRoomSheet.swift
//  CasaVault
//
//  Created by Lior Shor on 27/02/2026.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AddRoomSheet {
    @ObservableState
    struct State: Equatable {
        var roomName: String = ""
        var selectedIcon: String? = nil
    }

    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case roomNameChanged(String)
            case iconChanged(String?)
            case saveTapped
            case cancelTapped
        }

        @CasePathable
        enum Delegate: Equatable {
            case roomSaved(String, String?)
        }

        case view(View)
        case delegate(Delegate)
    }

    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)

            case .delegate:
                return .none
            }
        }
    }

    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case let .roomNameChanged(name):
            state.roomName = name
            return .none

        case let .iconChanged(icon):
            state.selectedIcon = icon
            return .none

        case .saveTapped:
            guard !state.roomName.isEmpty else {
                return .none
            }
            return .run { [roomName = state.roomName, icon = state.selectedIcon] send in
                await send(.delegate(.roomSaved(roomName, icon)))
                await dismiss()
            }

        case .cancelTapped:
            return .run { _ in
                await dismiss()
            }
        }
    }
}
