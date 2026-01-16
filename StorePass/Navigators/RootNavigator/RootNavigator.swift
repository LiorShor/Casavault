//
//  RootNavigator.swift
//  StorePass
//
//  Created by Lior Shor on 15/01/2026.
//

import Foundation
import ComposableArchitecture

@MainActor
@Reducer
struct RootNavigator {
    
    @ObservableState
    struct State: Equatable {
        var destination: Destination.State
        
        init(destination: Destination.State = .splash(Splash.State())) {
            self.destination = destination
        }
    }
    
    enum Action {
        case destination(Destination.Action)
    }
    
    public init() {}

        
    var body: some Reducer<State, Action> {
        Scope(state: \.destination, action: \.destination, child: Destination.init)
        
        Reduce { state, action in
            switch action {
            case .destination(.splash(.navigation(.splashCompleted))):
                state.destination = .home(HomeNavigator.State())
                return .none
                
            case .destination:
                return .none
            }
        }
    }
}

extension RootNavigator {
    
    @Reducer
    struct Destination {
        @ObservableState
        enum State: Equatable {
            case splash(Splash.State)
            case home(HomeNavigator.State)
        }
        
        enum Action {
            case splash(Splash.Action)
            case home(HomeNavigator.Action)
        }
        
        var body: some Reducer<State, Action> {
            Scope(state: \.splash, action: \.splash, child: Splash.init)
            Scope(state: \.home, action: \.home, child: HomeNavigator.init)
        }
    }
}
