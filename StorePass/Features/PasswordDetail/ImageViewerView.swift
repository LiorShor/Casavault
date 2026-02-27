//
//  ImageViewerView.swift
//  StorePass
//
//  Created by Lior Shor on 27/02/2026.
//

import SwiftUI
import ComposableArchitecture

struct ImageViewerView: View {
    @Bindable var store: StoreOf<ImageViewer>
    
    var body: some View {
        NavigationStack {
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
                                    store.send(.view(.scaleChanged(value)))
                                }
                                .onEnded { value in
                                    store.send(.view(.scaleEnded(value)))
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                store.send(.view(.doubleTapped))
                            }
                        }
                }
            }
            .navigationTitle(store.attachment.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.view(.closeTapped))
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}
