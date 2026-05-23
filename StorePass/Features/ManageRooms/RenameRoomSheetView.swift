//
//  RenameRoomSheetView.swift
//  StorePass
//

import SwiftUI
import ComposableArchitecture

struct RenameRoomSheetView: View {
    @Bindable var store: StoreOf<RenameRoomSheet>
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: store.selectedIcon ?? "pencil.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.monochrome)
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.tint)
                        .padding(.top, 40)
                        .animation(.spring(response: 0.3), value: store.selectedIcon)

                    Text(.localized(.renameRoom))
                        .font(.title)
                        .fontWeight(.semibold)

                    TextField(.localized(.roomName), text: $store.newName.sending(\.view.nameChanged))
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                        .font(.largeTitle)
                        .focused($isTextFieldFocused)
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                        .overlay(alignment: .leading) {
                            if !store.newName.isEmpty {
                                Button {
                                    store.send(.view(.nameChanged("")))
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .padding(12)
                                        .contentShape(Rectangle())
                                }
                                .padding(.leading, 48)
                            }
                        }

                    RoomIconPickerView(selectedIcon: store.selectedIcon) { icon in
                        store.send(.view(.iconChanged(icon)))
                    }

                    Button {
                        store.send(.view(.saveTapped))
                    } label: {
                        Text(.localized(.save))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(store.newName.isEmpty || (store.newName == store.originalName && store.selectedIcon == store.originalIcon))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.view(.cancelTapped))
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .presentationDetents([.large])
    }
}
