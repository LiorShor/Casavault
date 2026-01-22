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
    
    struct State: Equatable {
        
    }
    
    enum Action: Equatable {
        case onContinueButtonTapped(String, String)
        case onCancelButtonTapped
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onContinueButtonTapped(let name, let value):
                return .run { send in
                    let password = Password(name: name, value: value, createdAt: Date(), updatedAt: nil)
                    await passwords.addPassword(password)
                    await dismiss()
                }
            case .onCancelButtonTapped:
                return .run { _ in
                    await dismiss()
                }
            }
        }
    }
}
