//
//  InsertDeviceView.swift
//  StorePass
//
//  Created by Lior Shor on 09/08/2025.
//

import SwiftUI
import ComposableArchitecture

struct InsertPasswordView: View {
    @FocusState private var isFocused: Bool
    @Bindable var store: StoreOf<InsertPassword>
    @State private var inputText: String = .empty

    init(store: StoreOf<InsertPassword>) {
        self.store = store
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "key.horizontal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(minWidth: 50, maxWidth: 150, minHeight: 25, maxHeight: 100)
                    .layoutPriority(-1)
                    .foregroundStyle(.yellow)
                Text(.setupCode)
                    .font(.title)
                Text(.localized(.setupCodeInstructions))
                    .multilineTextAlignment(.center)
                TextField(.localized(.deviceCodePlaceholder), text: $inputText)
                    .onChange(of: inputText) { oldValue, newValue in
                        store.send(.onInputChange(newValue))
                        inputText = store.code
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .clipShape(Capsule())
                    .focused($isFocused)
                    .overlay(alignment: .trailing) {
                        if !store.code.isEmpty {
                            Image(systemName: store.isValidHomeKitCode ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundStyle(store.isValidHomeKitCode ? .green : .red)
                                .padding(.trailing, 20)
                        }
                    }
                    .overlay(alignment: .leading) {
                        if !store.code.isEmpty {
                            Button {
                                store.send(.onClearCodeButtonTapped)
                                inputText = store.code
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .padding(.leading, 20)
                        }
                    }
                
                Text(.localized(.enterDeviceTitle))
                TextField(.localized(.deviceNamePlaceholder), text: $store.deviceName)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .keyboardType(.default)
                    .clipShape(Capsule())
                    .focused($isFocused)
                    .overlay(alignment: .leading) {
                        if !store.deviceName.isEmpty {
                            Button {
                                store.send(.onClearDeviceNameButtonTapped)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .padding(.leading, 20)
                        }
                    }
                Spacer()
                Button {
                    store.send(.onContinueButtonTapped)
                } label: {
                    Text(.localized(.continueButton))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .padding(.vertical)
                .buttonStyle(.glassProminent)
                .disabled(!store.canContinue)
            }
            .padding(.horizontal, 25)
            .toolbar {
                ToolbarItem {
                    Button {
                        store.send(.onCancelButtonTapped)
                    } label: {
                        Label(.localized(.closeButton), systemImage: "xmark")
                    }
                }
            }
        }
        .onTapGesture {
            isFocused = false
        }
    }
}

#Preview {
    InsertPasswordView(store: Store(
        initialState: InsertPassword.State(),
        reducer: { InsertPassword() }
    ))
}
