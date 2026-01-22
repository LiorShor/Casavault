//
//  InsertDeviceView.swift
//  StorePass
//
//  Created by Lior Shor on 09/08/2025.
//

import SwiftUI
import ComposableArchitecture

struct InsertPasswordView: View {
    @State var code: String = .empty
    @State var deviceName: String = .empty
    @FocusState private var isFocused: Bool
    let store: StoreOf<InsertPassword>
    init(store: StoreOf<InsertPassword>) {
        self.store = store
    }
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "key.horizontal.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 100)
                    .foregroundStyle(.yellow)
                Text(.setupCode)
                    .font(.title)
                Text(.localized(.setupCodeInstructions))
                    .multilineTextAlignment(.center)
                TextField("", text: $code)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .clipShape(Capsule())
                    .focused($isFocused)
                
                Text(.localized(.enterDeviceTitle))
                TextField(.localized(.deviceNamePlaceholder), text: $deviceName)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .clipShape(Capsule())
                    .focused($isFocused)
                Spacer()
                Button {
                    store.send(.onContinueButtonTapped(code, deviceName))
                } label: {
                    Text(.localized(.continueButton))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .padding(.vertical)
                .buttonStyle(.glassProminent)
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
