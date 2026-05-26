//
//  Splash.swift
//  CasaVault
//
//  Created by Lior Shor on 15/01/2026.
//

import ComposableArchitecture

@Reducer
struct Splash {
    @ObservableState
    struct State: Equatable {
        init() {}
    }
    
    enum Action: ViewAction, Equatable {
        @CasePathable
        enum View: Equatable {
            case onAppear
        }
        
        @CasePathable
        enum Navigation: Equatable {
            case splashCompleted
        }
        
        case view(View)
        case navigation(Navigation)
        case fetchPasswords

    }
    
    @Dependency(\.interactor) private var interactor
    
    init() {}
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
                
            case .fetchPasswords:
                return .run { send in
                    let genresResult = await interactor.fetchPasswords()
                        await send(.navigation(.splashCompleted))
                }
            case .navigation:
                return .none
            }
        }
    }
    
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            return .send(.fetchPasswords)
        }
    }
}

extension DependencyValues {
    fileprivate var interactor: SplashInteractor {
        get { self[SplashInteractor.self] }
    }
}
