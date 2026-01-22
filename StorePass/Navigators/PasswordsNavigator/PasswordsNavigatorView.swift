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
                .navigationTitle(.passwords)
            }
            .sheet(item: $store.scope(state: \.insertPassword, action: \.insertPassword)) { insertStore in
                NavigationStack {
                    InsertPasswordView(store: insertStore)
                }
            }
            .sheet(item: $store.scope(state: \.passwordDetail, action: \.passwordDetail)) { _ in
                // Password detail view (you can create this later)
                Text(.passwordDetails)
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
