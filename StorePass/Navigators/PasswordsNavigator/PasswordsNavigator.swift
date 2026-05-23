//
//  PasswordsNavigator.swift
//  StorePass
//
//  Created by Lior Shor on 15/01/2026.
//

import Foundation
import ComposableArchitecture

@Reducer
struct PasswordsNavigator {
    @Dependency(\.passwordsUseCases) var passwordsUsecase
    
    @ObservableState
    struct State: Equatable {
        var passwordsCollection: PasswordsCollection.State
        @Presents var settings: Settings.State?
        @Presents var insertPassword: InsertPassword.State?
        @Presents var passwordDetailNavigator: PasswordDetailNavigator.State?
        @Presents var homeKitImport: HomeKitImport.State?
        var showingQRScannerForInsert: Bool = false
        
        init() {
            // Load saved view preferences
            let viewModeRaw = UserDefaults.standard.string(forKey: "passwordViewMode") ?? "list"
            let viewMode = PasswordViewMode(rawValue: viewModeRaw) ?? .list
            
            let groupingModeRaw = UserDefaults.standard.string(forKey: "passwordGroupingMode") ?? "all"
            let groupingMode = PasswordGroupingMode(rawValue: groupingModeRaw) ?? .all
            
            self.passwordsCollection = PasswordsCollection.State(
                passwords: [],
                viewMode: viewMode,
                groupingMode: groupingMode
            )
        }
    }
    
    enum Action {
        case onAppear
        case passwordsCollection(PasswordsCollection.Action)
        case settings(PresentationAction<Settings.Action>)
        case insertPassword(PresentationAction<InsertPassword.Action>)
        case passwordDetailNavigator(PresentationAction<PasswordDetailNavigator.Action>)
        case homeKitImport(PresentationAction<HomeKitImport.Action>)
        case passwordsLoaded([Password])
        case syncHomeKitRooms
        case qrScannerForInsertDismissed
        case qrCodeScannedForInsert(String)
        
        enum Delegate {
            case navigateToHomes
        }
        case delegate(Delegate)
    }
    
    init() {}
    
    var body: some Reducer<State, Action> {
        Scope(state: \.passwordsCollection, action: \.passwordsCollection) {
            PasswordsCollection()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    // Sync HomeKit rooms first
                    await send(.syncHomeKitRooms)
                    
                    let passwords = await passwordsUsecase.fetchPasswords()
                    await send(.passwordsLoaded(passwords))
                }
                
            case let .passwordsLoaded(passwords):
                state.passwordsCollection.passwords = passwords
                return .none
                
            case .passwordsCollection(.navigation(.onAddPassword)):
                state.insertPassword = InsertPassword.State()
                return .none
                
            case .passwordsCollection(.navigation(.onImportFromHomeKit)):
                state.homeKitImport = HomeKitImport.State()
                return .none
                
            case .insertPassword(.presented(.scanQRCode)):
                state.showingQRScannerForInsert = true
                return .none
                
            case .qrScannerForInsertDismissed:
                state.showingQRScannerForInsert = false
                return .none
                
            case let .qrCodeScannedForInsert(payload):
                state.showingQRScannerForInsert = false
                return .send(.insertPassword(.presented(.qrCodeScanned(payload))))
            case .passwordsCollection(.navigation(.presentSettings)):
                let themeRaw = UserDefaults.standard.string(forKey: "selectedTheme") ?? "system"
                let theme = AppTheme(rawValue: themeRaw) ?? .system
                let accentColorName = UserDefaults.standard.string(forKey: "accentColorName") ?? "AppBlue"
                state.settings = Settings.State(selectedTheme: theme, accentColorName: accentColorName)
                return .none
            case let .passwordsCollection(.navigation(.presentPassword(password))):
                state.passwordDetailNavigator = PasswordDetailNavigator.State(
                    password: password,
                    pendingRoomDeletions: state.passwordsCollection.pendingRoomDeletions
                )
                return .none
                
            case .passwordsCollection(.navigation(.navigateToHomes)):
                return .send(.delegate(.navigateToHomes))
                
            case .insertPassword(.dismiss):
                // Reload passwords after dismissing insert sheet
                let currentHomeId = state.passwordsCollection.currentHomeId
                return .run { send in
                    if let homeId = currentHomeId {
                        let passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                        await send(.passwordsLoaded(passwords))
                    } else {
                        let passwords = await passwordsUsecase.fetchPasswords()
                        await send(.passwordsLoaded(passwords))
                    }
                }
                
            case .passwordDetailNavigator(.presented(.delegate(.passwordUpdated))):
                // Reload passwords after updating a password
                let currentHomeId = state.passwordsCollection.currentHomeId
                return .run { send in
                    if let homeId = currentHomeId {
                        let passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                        await send(.passwordsLoaded(passwords))
                    } else {
                        let passwords = await passwordsUsecase.fetchPasswords()
                        await send(.passwordsLoaded(passwords))
                    }
                }
                
            case .passwordDetailNavigator(.dismiss):
                // Reload passwords after dismissing detail (in case password was updated)
                let currentHomeId = state.passwordsCollection.currentHomeId
                return .run { send in
                    if let homeId = currentHomeId {
                        let passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                        await send(.passwordsLoaded(passwords))
                    } else {
                        let passwords = await passwordsUsecase.fetchPasswords()
                        await send(.passwordsLoaded(passwords))
                    }
                }
                
            case .settings(.dismiss):
                // No need to reload - HomeKit import moved to plus button
                return .none
                
            case .homeKitImport(.dismiss):
                // Reload passwords after dismissing HomeKit import
                let currentHomeId = state.passwordsCollection.currentHomeId
                return .run { send in
                    if let homeId = currentHomeId {
                        let passwords = await passwordsUsecase.fetchPasswordsForHome(homeId)
                        await send(.passwordsLoaded(passwords))
                    } else {
                        let passwords = await passwordsUsecase.fetchPasswords()
                        await send(.passwordsLoaded(passwords))
                    }
                }
                
            case .syncHomeKitRooms:
                @Dependency(\.homeKitService) var homeKitService
                return .run { send in
                    do {
                        // Fetch HomeKit devices
                        let homeKitDevices = try await homeKitService.fetchDevices()
                        
                        // Fetch existing passwords
                        let passwords = await passwordsUsecase.fetchPasswords()
                        
                        // Update rooms for passwords that have HomeKit identifiers
                        for password in passwords {
                            guard let homeKitId = password.homeKitUniqueIdentifier else { continue }
                            
                            // Find matching HomeKit device
                            if let homeKitDevice = homeKitDevices.first(where: { $0.uniqueIdentifier == homeKitId }) {
                                // Update room if it changed
                                if password.room != homeKitDevice.roomName {
                                    password.room = homeKitDevice.roomName
                                    password.updatedAt = Date()
                                    await passwordsUsecase.updatePassword(password)
                                }
                            }
                        }
                    } catch {
                        // Silently fail - not critical if sync fails
                    }
                }
                
            case .passwordsCollection, .insertPassword, .passwordDetailNavigator, .settings, .homeKitImport, .delegate:
                return .none
            }
        }
        .ifLet(\.$settings, action: \.settings) {
            Settings()
        }
        .ifLet(\.$insertPassword, action: \.insertPassword) {
            InsertPassword()
        }
        .ifLet(\.$passwordDetailNavigator, action: \.passwordDetailNavigator) {
            PasswordDetailNavigator()
        }
        .ifLet(\.$homeKitImport, action: \.homeKitImport) {
            HomeKitImport()
        }
    }
}

extension PasswordsNavigator {
}
