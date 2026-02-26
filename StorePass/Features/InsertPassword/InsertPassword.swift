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
        var selectedIcon: String? = nil
        
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
                "outlet.fill",
                "switch.2",
                "sensor.fill",
                "window.ceiling.closed",
                "air.purifier.fill",
                "humidifier.fill"
            ]
        }
        
        // HomeKit code validation
        var isValidHomeKitCode: Bool {
            let homeKitCodeRegex = /^\d{3}-\d{2}-\d{3}$/
            return code.wholeMatch(of: homeKitCodeRegex) != nil
        }
        
        var canContinue: Bool {
            isValidHomeKitCode && !deviceName.isEmpty
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
        case saveNewRoom
        case cancelAddingRoom
        case iconSelected(String?)
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let defaultHome = await homeUseCases.getDefaultHome()
                    await send(.currentHomeLoaded(defaultHome))
                    
                    // Load existing rooms
                    let passwords = await passwords.fetchPasswords()
                    let rooms = Set(passwords.compactMap { $0.room }).sorted()
                    await send(.roomsLoaded(rooms))
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
                // Auto-format HomeKit code when user types (XXX-XX-XXX format, max 10 chars)
                let digits = text.filter { $0.isNumber }
                let limitedDigits = String(digits.prefix(10))
                
                var formatted: String = .empty
                for (index, digit) in limitedDigits.enumerated() {
                    if index == 3 || index == 5 {
                        formatted += "-"
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
                    let password = Password(name: deviceName, value: code, room: room, icon: icon, homeId: homeId, createdAt: Date(), updatedAt: nil)
                    await passwords.addPassword(password)
                    await dismiss()
                }
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
