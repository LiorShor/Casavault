//
//  PasswordDetailNavigatorView.swift
//  StorePass
//
//  Created by Lior Shor on 27/02/2026.
//

import SwiftUI
import ComposableArchitecture

struct PasswordDetailNavigatorView: View {
    @Bindable var store: StoreOf<PasswordDetailNavigator>
    
    var body: some View {
        NavigationStack {
            PasswordDetailView(store: store.scope(state: \.passwordDetail, action: \.passwordDetail))
        }
        .sheet(item: $store.scope(state: \.addRoomSheet, action: \.addRoomSheet)) { addRoomStore in
            AddRoomSheetView(store: addRoomStore)
        }
        .confirmationDialog(
            "",
            isPresented: Binding(
                get: { store.showingImageSourcePicker },
                set: { if !$0 { store.send(.view(.imageSourcePickerCancelled)) } }
            ),
            titleVisibility: .hidden
        ) {
            Button {
                store.send(.view(.imageSourcePickerCameraSelected))
            } label: {
                Text(.localized(.takePhoto))
            }
            
            Button {
                store.send(.view(.imageSourcePickerPhotoLibrarySelected))
            } label: {
                Text(.localized(.chooseFromLibrary))
            }
            
            Button(.localized(.cancel), role: .cancel) {
                store.send(.view(.imageSourcePickerCancelled))
            }
        }
        .sheet(isPresented: Binding(
            get: { store.showingImagePicker },
            set: { if !$0 { store.send(.view(.imagePickerDismissed)) } }
        )) {
            ImagePickerView(sourceType: store.pendingImageSourceType) { imageData in
                store.send(.view(.imageSelected(imageData)))
            }
        }
        .sheet(item: $store.scope(state: \.imageViewer, action: \.imageViewer)) { imageViewerStore in
            ImageViewerView(store: imageViewerStore)
        }
    }
}
