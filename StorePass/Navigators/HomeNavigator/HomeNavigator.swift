//
//  HomeNavigator.swift
//  StorePass
//
//  Created by Lior Shor on 15/01/2026.
//

import Foundation
import ComposableArchitecture

@MainActor
@Reducer
struct HomeNavigator {
    
    @ObservableState
    struct State: Equatable {
        var selectedTab: TabType = .passwords
        
        var passwords = PasswordsNavigator.State()
//        var search = SearchNavigator.State()
        
        init(selectedTab: TabType = .passwords) {
            self.selectedTab = selectedTab
        }
    }
    
    enum Action {
        case onTabSelection(TabType)
        case passwords(PasswordsNavigator.Action)
//        case search(SearchNavigator.Action)
    }
    
    init() {}
    
    var body: some Reducer<State, Action> {
    
        Scope(state: \.passwords, action: \.passwords, child: PasswordsNavigator.init)
        
//        Scope(state: \.search, action: \.search, child: SearchNavigator.init)
        
        Reduce { state, action in
        switch action {
            case let .onTabSelection(tab):
                state.selectedTab = tab
                return .none
                
            case .passwords/*, .search*/:
                return .none
            }
        }
    }
}

extension HomeNavigator {
    
    enum TabType {
        case passwords
    }
}
