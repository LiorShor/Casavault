//
//  RootNavigatorView.swift
//  StorePass
//
//  Created by Lior Shor on 16/01/2026.
//

import SwiftUI
import ComposableArchitecture

extension RootNavigator {
    struct ContentView: View {
        
        public let store: StoreOf<RootNavigator>
        
        public init(store: StoreOf<RootNavigator>) {
            self.store = store
        }
        
        public var body: some View {
            Group {
                switch store.destination {
                case .splash:
                    if let store = store.scope(state: \.destination.splash, action: \.destination.splash) {
                        SplashView(store: store)
                    }
                    
                case .home:
                    if let store = store.scope(state: \.destination.home, action: \.destination.home) {
                        HomeNavigator.ContentView(store: store)
                    }
                }
            }
            .animation(.easeInOut, value: store.destination)
        }
    }
}

#Preview {
    RootNavigator.ContentView(
        store: Store(
            initialState: RootNavigator.State(),
            reducer: RootNavigator.init
        )
    )
}
