//
//  ImageSourcePickerSheet.swift
//  StorePass
//
//  Created by Lior Shor on 27/02/2026.
//

import SwiftUI
import ComposableArchitecture

struct ImageSourcePickerSheet: View {
    let store: StoreOf<PasswordDetailNavigator>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Camera option
            Button {
                store.send(.view(.imageSourcePickerCameraSelected))
                dismiss()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32)
                    
                    Text(.localized(.takePhoto))
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            
            Divider()
                .padding(.leading, 68)
            
            // Photo library option
            Button {
                store.send(.view(.imageSourcePickerPhotoLibrarySelected))
                dismiss()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32)
                    
                    Text(.localized(.chooseFromLibrary))
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .presentationDetents([.height(140)])
        .presentationDragIndicator(.visible)
    }
}
