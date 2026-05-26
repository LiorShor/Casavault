//
//  ImageSourcePickerView.swift
//  CasaVault
//
//  Created by Lior Shor on 27/02/2026.
//

import SwiftUI
import ComposableArchitecture

struct ImageSourcePickerView: View {
    let store: StoreOf<ImageSourcePicker>
    
    var body: some View {
        // This is presented as a confirmationDialog, so we don't need to build the UI here
        // The view is managed by the parent navigator
        EmptyView()
    }
}
