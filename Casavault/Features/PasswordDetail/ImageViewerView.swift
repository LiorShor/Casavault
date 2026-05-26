//
//  ImageViewerView.swift
//  CasaVault
//
//  Created by Lior Shor on 27/02/2026.
//

import SwiftUI
import ComposableArchitecture

struct ImageViewerView: View {
    @Bindable var store: StoreOf<ImageViewer>
    
    var body: some View {
        NavigationStack {
            imageContent
                .navigationTitle(store.attachment.fileName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    closeButton
                }
        }
    }
    
    private var imageContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let imageData = store.attachment.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(store.scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                _ = store.send(.view(.scaleChanged(value)))
                            }
                            .onEnded { value in
                                _ = store.send(.view(.scaleEnded(value)))
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            _ = store.send(.view(.doubleTapped))
                        }
                    }
            }
        }
    }
    
    private var closeButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(.localized(.closeButton), systemImage: "xmark") {
                store.send(.view(.closeTapped))
            }
        }
    }
}
