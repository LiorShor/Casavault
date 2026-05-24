//
//  ImageSourcePicker.swift
//  CasaVault
//
//  Created by Lior Shor on 27/02/2026.
//

import Foundation
import ComposableArchitecture
import UIKit

@Reducer
struct ImageSourcePicker {
    @ObservableState
    struct State: Equatable {
        // Empty state - this is just for the confirmation dialog
    }
    
    enum Action: Equatable {
        @CasePathable
        enum View: Equatable {
            case cameraSelected
            case photoLibrarySelected
            case cancelTapped
        }
        
        @CasePathable
        enum Delegate: Equatable {
            case sourceSelected(UIImagePickerController.SourceType)
        }
        
        case view(View)
        case delegate(Delegate)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return reduceViewAction(&state, viewAction)
                
            case .delegate:
                return .none
            }
        }
    }
    
    private func reduceViewAction(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .cameraSelected:
            return .run { send in
                await send(.delegate(.sourceSelected(.camera)))
                await dismiss()
            }
            
        case .photoLibrarySelected:
            return .run { send in
                await send(.delegate(.sourceSelected(.photoLibrary)))
                await dismiss()
            }
            
        case .cancelTapped:
            return .run { _ in
                await dismiss()
            }
        }
    }
}
