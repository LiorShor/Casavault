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
    
    @ObservableState
    struct State: Equatable {
    }
    
    enum Action {

    }
    
    init() {}
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            }
        }
    }
}

extension PasswordsNavigator {
}
