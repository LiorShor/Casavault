//
//  RenameRoomSheet.swift
//  CasaVault
//

import Foundation
import ComposableArchitecture

@Reducer
struct RenameRoomSheet {
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    struct State: Equatable {
        let originalName: String
        let originalIcon: String?
        var newName: String
        var selectedIcon: String?

        init(originalName: String, currentIcon: String? = nil) {
            self.originalName = originalName
            self.originalIcon = currentIcon
            self.newName = originalName
            self.selectedIcon = currentIcon
        }
    }

    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case nameChanged(String)
            case iconChanged(String?)
            case saveTapped
            case cancelTapped
        }

        @CasePathable
        enum Delegate: Equatable {
            case roomRenamed(oldName: String, newName: String, icon: String?)
        }

        case view(View)
        case delegate(Delegate)
    }

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
        case let .nameChanged(name):
            state.newName = name
            return .none

        case let .iconChanged(icon):
            state.selectedIcon = icon
            return .none

        case .saveTapped:
            guard !state.newName.isEmpty else {
                return .run { _ in await dismiss() }
            }
            return .run { [orig = state.originalName, new = state.newName, icon = state.selectedIcon] send in
                await send(.delegate(.roomRenamed(oldName: orig, newName: new, icon: icon)))
                await dismiss()
            }

        case .cancelTapped:
            return .run { _ in await dismiss() }
        }
    }
}
