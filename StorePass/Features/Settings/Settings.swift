//
//  Settings.swift
//  StorePass
//
//  Created by Lior Shor on 25/01/2026.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import Localization

enum AppLanguage: String, CaseIterable, Equatable {
    case english = "en"
    case hebrew = "he"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hebrew: return "עברית"
        }
    }
}

enum AppTheme: String, CaseIterable, Equatable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return String.localized(.themeSystem)
        case .light: return String.localized(.themeLight)
        case .dark: return String.localized(.themeDark)
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Reducer
struct Settings {
    @Dependency(\.passwordsUseCases) var passwordsUsecase
    @Dependency(\.dismiss) var dismiss
    
    @ObservableState
    struct State: Equatable {
        var selectedTheme: AppTheme
        var isExportingPasswords: Bool = false
        @Presents var shareSheet: ShareSheetState?
        @Presents var homeKitImport: HomeKitImport.State?
        
        init(selectedTheme: AppTheme = .system) {
            self.selectedTheme = selectedTheme
        }
    }
    
    struct ShareSheetState: Equatable, Identifiable {
        let id = UUID()
        let fileURL: URL
    }
    
    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case onExportButtonTapped
            case themeChanged(AppTheme)
            case onOpenLanguageSettingsButtonTapped
            case onImportFromHomeKitButtonTapped
            case onDismiss
        }
        
        @CasePathable
        enum Internal: Equatable {
            case exportPasswordsCompleted(URL?)
        }
        
        @CasePathable
        enum Navigation: Equatable {
        }
        
        case view(View)
        case `internal`(Internal)
        case navigation(Navigation)
        case shareSheet(PresentationAction<Never>)
        case homeKitImport(PresentationAction<HomeKitImport.Action>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
                
            case let .internal(internalAction):
                return reduceInternalAction(&state, internalAction)
                
            case .navigation, .shareSheet, .homeKitImport:
                return .none
            }
        }
        .ifLet(\.$shareSheet, action: \.shareSheet) {
            EmptyReducer()
        }
        .ifLet(\.$homeKitImport, action: \.homeKitImport) {
            HomeKitImport()
        }
    }
    
    @MainActor
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case let .themeChanged(theme):
            state.selectedTheme = theme
            UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
            return .none
            
        case .onOpenLanguageSettingsButtonTapped:
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return .none
            }
            UIApplication.shared.open(settingsUrl)
            return .none
            
        case .onExportButtonTapped:
            state.isExportingPasswords = true
            return .run { send in
                let passwords = await passwordsUsecase.fetchPasswords()
                let fileURL = await exportPasswords(passwords)
                await send(.internal(.exportPasswordsCompleted(fileURL)))
            }
            
        case .onImportFromHomeKitButtonTapped:
            state.homeKitImport = HomeKitImport.State()
            return .none
            
        case .onDismiss:
            return .run { _ in
                await dismiss()
            }
        }
    }
    
    @MainActor
    private func reduceInternalAction(_ state: inout State, _ action: Action.Internal) -> Effect<Action> {
        switch action {
        case let .exportPasswordsCompleted(fileURL):
            state.isExportingPasswords = false
            if let fileURL {
                state.shareSheet = ShareSheetState(fileURL: fileURL)
            }
            return .none
        }
    }
    
    private func exportPasswords(_ passwords: [Password]) async -> URL? {
        let csvString = generateCSV(from: passwords)
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("passwords_export_\(Date().timeIntervalSince1970).csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error exporting passwords: \(error)")
            return nil
        }
    }
    
    private func generateCSV(from passwords: [Password]) -> String {
        var csvString = "Name,Password,Created At,Updated At\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for password in passwords {
            let name = password.name.replacingOccurrences(of: ",", with: ";")
            let value = password.value.replacingOccurrences(of: ",", with: ";")
            let createdAt = dateFormatter.string(from: password.createdAt)
            let updatedAt = password.updatedAt != nil ? dateFormatter.string(from: password.updatedAt!) : ""
            
            csvString += "\(name),\(value),\(createdAt),\(updatedAt)\n"
        }
        
        return csvString
    }
}

