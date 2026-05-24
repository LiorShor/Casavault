//
//  ImageViewer.swift
//  CasaVault
//
//  Created by Lior Shor on 27/02/2026.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ImageViewer {
    @ObservableState
    struct State: Equatable {
        var attachment: PasswordAttachment
        var scale: CGFloat = 1.0
        var lastScale: CGFloat = 1.0
        
        init(attachment: PasswordAttachment) {
            self.attachment = attachment
        }
    }
    
    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case scaleChanged(CGFloat)
            case scaleEnded(CGFloat)
            case doubleTapped
            case closeTapped
        }
        
        case view(View)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
            }
        }
    }
    
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case let .scaleChanged(value):
            state.scale = state.lastScale * value
            return .none
            
        case let .scaleEnded(value):
            state.lastScale = state.scale
            return .none
            
        case .doubleTapped:
            if state.scale > 1.0 {
                state.scale = 1.0
                state.lastScale = 1.0
            } else {
                state.scale = 2.0
                state.lastScale = 2.0
            }
            return .none
            
        case .closeTapped:
            return .run { _ in
                await dismiss()
            }
        }
    }
}
