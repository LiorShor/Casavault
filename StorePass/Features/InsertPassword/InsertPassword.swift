//
//  InsertDevice.swift
//  StorePass
//
//  Created by Lior Shor on 09/08/2025.
//

import Foundation
import ComposableArchitecture
import SwiftData


@Reducer
struct InsertPassword {
    @Dependency(\.useCases.passwords) var passwords
    @Dependency(\.homeUseCases) var homeUseCases
    @Dependency(\.dismiss) var dismiss
    
    @ObservableState
    struct State: Equatable {
        var code: String = .empty
        var deviceName: String = .empty
        var currentHomeId: UUID?
        var availableRooms: [String] = []
        var selectedRoom: String?
        var isAddingNewRoom: Bool = false
        var newRoomName: String = .empty
        
        // Available SF Symbols for devices
        var availableIcons: [String] {
            [
                "lightbulb.fill",
                "lock.fill",
                "fan.fill",
                "thermometer.medium",
                "speaker.wave.2.fill",
                "camera.fill",
                "tv.fill",
                "poweroutlet.type.h.square.fill",
                "switch.2",
                "sensor.fill",
                "window.ceiling.closed",
                "air.purifier.fill",
                "humidifier.fill"
            ]
        }
        
        var selectedIcon: String? = "lightbulb.fill"
        
        // HomeKit/Matter code validation
        var isValidCode: Bool {
            let homeKitCodeRegex = /^\d{3}-\d{2}-\d{3}$/  // XXX-XX-XXX (8 digits)
            let matterCodeRegex = /^\d{4}-\d{3}-\d{4}$/   // XXXX-XXX-XXXX (11 digits)
            return code.wholeMatch(of: homeKitCodeRegex) != nil || 
                   code.wholeMatch(of: matterCodeRegex) != nil
        }
        
        var canContinue: Bool {
            isValidCode && !deviceName.isEmpty
        }
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<InsertPassword.State>)
        case onInputChange(String)
        case onContinueButtonTapped
        case onCancelButtonTapped
        case onClearCodeButtonTapped
        case onClearDeviceNameButtonTapped
        case onAppear
        case currentHomeLoaded(Home?)
        case roomsLoaded([String])
        case roomSelected(String?)
        case addNewRoomTapped
        case clearNewRoomName
        case saveNewRoom
        case cancelAddingRoom
        case iconSelected(String?)
        case scanQRCode
        case qrCodeScanned(String)
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let defaultHome = await homeUseCases.getDefaultHome()
                    await send(.currentHomeLoaded(defaultHome))
                    
                    // Load existing rooms only for the current home
                    if let currentHomeId = defaultHome?.id {
                        let passwords = await passwords.fetchPasswordsForHome(currentHomeId)
                        let rooms = Set(passwords.compactMap { $0.room }).sorted()
                        await send(.roomsLoaded(rooms))
                    }
                }
                
            case let .currentHomeLoaded(home):
                state.currentHomeId = home?.id
                return .none
                
            case let .roomsLoaded(rooms):
                state.availableRooms = rooms
                return .none
                
            case let .roomSelected(room):
                state.selectedRoom = room
                return .none
                
            case let .iconSelected(icon):
                state.selectedIcon = icon
                return .none
                
            case .addNewRoomTapped:
                state.isAddingNewRoom = true
                state.newRoomName = .empty
                return .none
                
            case .clearNewRoomName:
                state.newRoomName = .empty
                return .none
                
            case .saveNewRoom:
                guard !state.newRoomName.isEmpty else {
                    state.isAddingNewRoom = false
                    return .none
                }
                let roomName = state.newRoomName
                state.selectedRoom = roomName
                state.isAddingNewRoom = false
                state.newRoomName = .empty
                // Add to available rooms if not already there
                if !state.availableRooms.contains(roomName) {
                    state.availableRooms.append(roomName)
                    state.availableRooms.sort()
                }
                return .none
                
            case .cancelAddingRoom:
                state.isAddingNewRoom = false
                state.newRoomName = .empty
                return .none
                
            case let .onInputChange(text):
                // Auto-format HomeKit/Matter code when user types
                // HomeKit: XXX-XX-XXX (8 digits, max 10 chars with dashes)
                // Matter: XXXX-XXX-XXXX (11 digits, max 13 chars with dashes)
                let digits = text.filter { $0.isNumber }
                let limitedDigits = String(digits.prefix(11)) // Support up to 11 digits for Matter
                
                var formatted: String = .empty
                for (index, digit) in limitedDigits.enumerated() {
                    // HomeKit format: 3-2-3
                    // Matter format: 4-3-4
                    if limitedDigits.count <= 8 {
                        // HomeKit format
                        if index == 3 || index == 5 {
                            formatted += "-"
                        }
                    } else {
                        // Matter format
                        if index == 4 || index == 7 {
                            formatted += "-"
                        }
                    }
                    formatted.append(digit)
                }
                
                state.code = formatted
                return .none
                
            case .binding:
                return .none
            
            case .onContinueButtonTapped:
                let code = state.code
                let deviceName = state.deviceName
                let homeId = state.currentHomeId
                let room = state.selectedRoom
                let icon = state.selectedIcon
                return .run { send in
                    @Dependency(\.databaseService.context) var getContext
                    let context = try getContext()
                    let password = Password(context: context, name: deviceName, value: code, room: room, icon: icon, homeId: homeId, homeKitUniqueIdentifier: nil, notes: nil)
                    await passwords.addPassword(password)
                    await dismiss()
                }
                
            case .scanQRCode:
                // This will be handled by the navigator
                return .none
                
            case let .qrCodeScanned(payload):
                // Store the scanned QR code as the password value
                state.code = payload
                return .none
            case .onClearCodeButtonTapped:
                state.code = .empty
                return .none
            case .onClearDeviceNameButtonTapped:
                state.deviceName = .empty
                return .none
            case .onCancelButtonTapped:
                return .run { _ in
                    await dismiss()
                }
            }
        }
    }
}
