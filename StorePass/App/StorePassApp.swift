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
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    
    private var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootNavigator.ContentView(
                store: Store(
                    initialState: RootNavigator.State(),
                    reducer: RootNavigator.init
                )
            )
            .preferredColorScheme(colorScheme)
            .environment(\.locale, Locale(identifier: selectedLanguage))
        }
    }
}
