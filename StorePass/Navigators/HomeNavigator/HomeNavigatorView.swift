//
//  HomeNavigatorView.swift
//  StorePass
//
//  Created by Lior Shor on 15/01/2026.
//

import SwiftUI
import ComposableArchitecture

extension HomeNavigator {

    struct ContentView: View {

        @Bindable var store: StoreOf<HomeNavigator>

        init(store: StoreOf<HomeNavigator>) {
            self.store = store
        }

        var body: some View {
            TabView(selection: $store.selectedTab.sending(\.onTabSelection)) {
                Tab(.localized(.passwords), systemImage: "list.bullet", value: TabType.passwords) {
                    PasswordsNavigator.ContentView(
                        store: store.scope(state: \.passwords, action: \.passwords)
                    )
                }

                Tab(.localized(.rooms), systemImage: "door.left.hand.open", value: TabType.rooms) {
                    ManageRoomsView(
                        store: store.scope(state: \.rooms, action: \.rooms)
                    )
                }

                Tab(.localized(.homes), systemImage: "house.fill", value: TabType.homes) {
                    HomesNavigator.ContentView(
                        store: store.scope(state: \.homes, action: \.homes)
                    )
                }
            }
        }
    }
}

#Preview {
    HomeNavigator.ContentView(
        store: Store(
            initialState: HomeNavigator.State(),
            reducer: HomeNavigator.init
        )
    )
}
