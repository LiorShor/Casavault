//
//  AddRoomSheetView.swift
//  StorePass
//
//  Created by Lior Shor on 27/02/2026.
//

import SwiftUI
import ComposableArchitecture

struct AddRoomSheetView: View {
    @Bindable var store: StoreOf<AddRoomSheet>
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: store.selectedIcon ?? "door.left.hand.open")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(Color.accentColor)
                        .foregroundStyle(.tint)
                        .padding(.top, 40)
                        .animation(.spring(response: 0.3), value: store.selectedIcon)

                    Text(.localized(.addNewRoom))
                        .font(.title)
                        .fontWeight(.semibold)

                    TextField(.localized(.roomName), text: $store.roomName.sending(\.view.roomNameChanged))
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                        .font(.largeTitle)
                        .focused($isTextFieldFocused)
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                        .overlay(alignment: .leading) {
                            if !store.roomName.isEmpty {
                                Button {
                                    store.send(.view(.roomNameChanged("")))
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
                    .disabled(store.roomName.isEmpty)
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
