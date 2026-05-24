//
//  HomesCollection.swift
//  CasaVault
//
//  Created by Lior Shor on 26/02/2026.
//

import Foundation
import UIKit
import ComposableArchitecture
import SwiftData
import SwiftUI

@Reducer
struct HomesCollection {
    @Dependency(\.homeUseCases) var homeUseCases
    
    @ObservableState
    struct State: Equatable {
        var homes: [Home] = []
        var defaultHomeId: UUID?
        var isImporting: Bool = false
        var showPermissionDeniedAlert: Bool = false
        var isAddingNewHome: Bool = false
        var newHomeName: String = ""

        var isHomeNameValid: Bool {
            !newHomeName.isEmpty && !homes.contains(where: { $0.name.lowercased() == newHomeName.lowercased() })
        }

        var homeNameExists: Bool {
            homes.contains(where: { $0.name.lowercased() == newHomeName.lowercased() })
        }

        init(homes: [Home] = []) {
            self.homes = homes
            self.defaultHomeId = homes.first(where: { $0.isDefault })?.id
        }
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        
        enum View: Equatable {
            case onHomeTap(Home)
            case onDeleteHome(Home)
            case onAddHomeButtonTapped
            case onImportFromHomeKitTapped
            case toggleDefaultHome(Home)
            case saveNewHome
            case cancelAddingHome
            case onSettingsButtonTapped
            case openSettings
        }
        
        @CasePathable
        enum Navigation: Equatable {
            case presentSettings
        }
        
        @CasePathable
        enum Internal: Equatable {
            case importPermissionDenied
        }

        case view(View)
        case `internal`(Internal)
        case navigation(Navigation)
        case homesLoaded([Home])
        case importCompleted
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)

            case .internal(.importPermissionDenied):
                state.isImporting = false
                state.showPermissionDeniedAlert = true
                return .none

            case .navigation:
                return .none
                
            case let .homesLoaded(homes):
                state.homes = homes
                state.defaultHomeId = homes.first(where: { $0.isDefault })?.id
                // Auto-mark as default if there's only one home and no default is set
                if homes.count == 1, let singleHome = homes.first, !singleHome.isDefault {
                    return .run { @MainActor [singleHome] send in
                        await homeUseCases.setDefaultHome(singleHome)
                        let updatedHomes = await homeUseCases.fetchHomes()
                        send(.homesLoaded(updatedHomes))
                    }
                }
                return .none
                
            case .importCompleted:
                state.isImporting = false
                // Reload all homes
                return .run { send in
                    let homes = await homeUseCases.fetchHomes()
                    await send(.homesLoaded(homes))
                }
            }
        }
    }
    
    @MainActor
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAddHomeButtonTapped:
            state.isAddingNewHome = true
            state.newHomeName = ""
            return .none
            
        case .onImportFromHomeKitTapped:
            state.isImporting = true
            return .run { send in
                do {
                    _ = try await homeUseCases.importFromHomeKit()
                    await send(.importCompleted)
                } catch HomeKitError.permissionDenied {
                    await send(.internal(.importPermissionDenied))
                } catch {
                    await send(.importCompleted)
                }
            }
            
        case let .onDeleteHome(home):
            return .run { @MainActor [home] send in
                await homeUseCases.removeHome(home)
                let updatedHomes = await homeUseCases.fetchHomes()
                send(.homesLoaded(updatedHomes))
            }
            
        case .onHomeTap:
            // Handle home selection if needed
            return .none
            
        case let .toggleDefaultHome(home):
            state.defaultHomeId = home.id  // immediate visual feedback
            return .run { @MainActor [home] send in
                await homeUseCases.setDefaultHome(home)
                let updatedHomes = await homeUseCases.fetchHomes()
                send(.homesLoaded(updatedHomes))
            }
            
        case .saveNewHome:
            guard !state.newHomeName.isEmpty else {
                state.isAddingNewHome = false
                return .none
            }
            
            let homeName = state.newHomeName
            state.isAddingNewHome = false
            state.newHomeName = ""
            
            return .run { @MainActor send in
                @Dependency(\.databaseService.context) var getContext
                let context = try getContext()
                let newHome = Home(context: context, name: homeName)
                await homeUseCases.addHome(newHome)
                let updatedHomes = await homeUseCases.fetchHomes()
                send(.homesLoaded(updatedHomes))
            }
            
        case .cancelAddingHome:
            state.isAddingNewHome = false
            state.newHomeName = ""
            return .none
            
        case .onSettingsButtonTapped:
            return .send(.navigation(.presentSettings))

        case .openSettings:
            return .run { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    await MainActor.run { UIApplication.shared.open(url) }
                }
            }
        }
    }
}
