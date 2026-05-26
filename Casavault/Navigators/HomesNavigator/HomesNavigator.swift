//
//  HomesNavigator.swift
//  CasaVault
//
//  Created by Lior Shor on 26/02/2026.
//

import Foundation
import CoreData
import ComposableArchitecture

@MainActor
@Reducer
struct HomesNavigator {
    @Dependency(\.homeUseCases) var homeUseCases
    
    @ObservableState
    struct State: Equatable {
        var homesCollection = HomesCollection.State()
        @Presents var settings: Settings.State?
        
        init() {}
    }
    
    enum Action {
        case homesCollection(HomesCollection.Action)
        case settings(PresentationAction<Settings.Action>)
        case onAppear
        case cloudKitRemoteChange
    }
    
    init() {}
    
    var body: some Reducer<State, Action> {
        Scope(state: \.homesCollection, action: \.homesCollection, child: HomesCollection.init)
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .run { @MainActor send in
                        let homes = await homeUseCases.fetchHomes()
                        send(.homesCollection(.homesLoaded(homes)))
                    },
                    .run { send in
                        let notifications = NotificationCenter.default.notifications(
                            named: .NSPersistentStoreRemoteChange
                        )
                        for await _ in notifications {
                            await send(.cloudKitRemoteChange)
                        }
                    }
                )

            case .cloudKitRemoteChange:
                return .run { @MainActor send in
                    let homes = await homeUseCases.fetchHomes()
                    send(.homesCollection(.homesLoaded(homes)))
                }
                
            case .homesCollection(.navigation(.presentSettings)):
                let themeRaw = UserDefaults.standard.string(forKey: "selectedTheme") ?? "system"
                let theme = AppTheme(rawValue: themeRaw) ?? .system
                let accentColorName = UserDefaults.standard.string(forKey: "accentColorName") ?? "AppBlue"
                state.settings = Settings.State(selectedTheme: theme, accentColorName: accentColorName)
                return .none
                
            case .settings(.dismiss):
                // Reload homes after dismissing settings
                return .run { @MainActor send in
                    let homes = await homeUseCases.fetchHomes()
                    send(.homesCollection(.homesLoaded(homes)))
                }
                
            case .homesCollection, .settings:
                return .none
            }
        }
        .ifLet(\.$settings, action: \.settings) {
            Settings()
        }
    }
}
