//
//  PasswordsNavigatorView.swift
//  StorePass
//
//  Created by Lior Shor on 22/01/2026.
//

import SwiftUI
import ComposableArchitecture

extension PasswordsNavigator {
    
    struct ContentView: View {
        
        @Bindable var store: StoreOf<PasswordsNavigator>
        
        init(store: StoreOf<PasswordsNavigator>) {
            self.store = store
        }
        
        var body: some View {
            NavigationStack {
                PasswordsCollectionView(
                    store: store.scope(state: \.passwordsCollection, action: \.passwordsCollection)
                )
                .navigationTitle(.localized(.passwords))
            }
            .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
                NavigationStack {
                    SettingsView(store: settingsStore)
                }
            }
            .sheet(item: $store.scope(state: \.insertPassword, action: \.insertPassword)) { insertStore in
                NavigationStack {
                    InsertPasswordView(store: insertStore)
                }
            }
            .sheet(item: $store.scope(state: \.passwordDetailNavigator, action: \.passwordDetailNavigator)) { detailNavigatorStore in
                PasswordDetailNavigatorView(store: detailNavigatorStore)
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

#Preview {
    PasswordsNavigator.ContentView(
        store: Store(
            initialState: PasswordsNavigator.State(),
            reducer: PasswordsNavigator.init
        )
    )
}
