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
    @Dependency(\.dismiss) var dismiss
    
    @ObservableState
    struct State: Equatable {
        var code: String = .empty
        var deviceName: String = .empty
        
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
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
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
                return .run { send in
                    let password = Password(name: deviceName, value: code, createdAt: Date(), updatedAt: nil)
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
