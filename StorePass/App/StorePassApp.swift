//
//  StorePassApp.swift
//  StorePass
//
//  Created by Lior Shor on 15/01/2026.
//

import SwiftUI
import ComposableArchitecture

@main
struct StorePassApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootNavigator.ContentView(
                store: Store(
                    initialState: RootNavigator.State(),
                    reducer: RootNavigator.init
                )
            )
        }
    }
}
