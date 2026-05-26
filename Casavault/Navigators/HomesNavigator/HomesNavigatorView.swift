//
//  HomesNavigatorView.swift
//  CasaVault
//
//  Created by Lior Shor on 26/02/2026.
//

import SwiftUI
import ComposableArchitecture

extension HomesNavigator {

    struct ContentView: View {
        
        @Bindable var store: StoreOf<HomesNavigator>
        
        init(store: StoreOf<HomesNavigator>) {
            self.store = store
        }
        
        var body: some View {
            HomesCollection.ContentView(
                store: store.scope(state: \.homesCollection, action: \.homesCollection)
            )
            .onAppear {
                store.send(.onAppear)
            }
            .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
                SettingsView(store: settingsStore)
            }
        }
    }
}

#Preview {
    HomesNavigator.ContentView(
        store: Store(
            initialState: HomesNavigator.State(),
            reducer: HomesNavigator.init
        )
    )
}
