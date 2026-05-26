//
//  InsertDeviceView.swift
//  CasaVault
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
        NavigationStack {
            VStack {
                Image(systemName: "key.horizontal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(minWidth: 50, maxWidth: 150, minHeight: 25, maxHeight: 100)
                    .layoutPriority(-1)
                    .foregroundStyle(.yellow)
                Text(.localized(.setupCode))
                    .font(.title)
                Text(.localized(.setupCodeInstructions))
                    .multilineTextAlignment(.center)
                TextField(.localized(.deviceCodePlaceholder), text: $inputText)
                    .onChange(of: inputText) { oldValue, newValue in
                        store.send(.onInputChange(newValue))
                        inputText = store.code
                    }
                    .onChange(of: store.code) { _, newCode in
                        if inputText != newCode {
                            inputText = newCode
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .clipShape(.capsule)
                    .focused($isFocused)
                    .overlay(alignment: .trailing) {
                        if !store.code.isEmpty {
                            Image(systemName: store.isValidCode ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundStyle(store.isValidCode ? .green : .red)
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
                                    .padding(12)
                                    .contentShape(Rectangle())
                            }
                            .padding(.leading, 8)
                        }
                    }
                
                // QR Code Scanner Button
                Button {
                    store.send(.scanQRCode)
                } label: {
                    Label(.localized(.scanQRCode), systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.vertical, 8)
                
                Text(.localized(.enterDeviceTitle))
                TextField(.localized(.deviceNamePlaceholder), text: $store.deviceName)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .keyboardType(.default)
                    .clipShape(.capsule)
                    .focused($isFocused)
                    .overlay(alignment: .leading) {
                        if !store.deviceName.isEmpty {
                            Button {
                                store.send(.onClearDeviceNameButtonTapped)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .padding(12)
                                    .contentShape(Rectangle())
                            }
                            .padding(.leading, 8)
                        }
                    }
                
                Picker(selection: Binding(
                    get: { store.selectedRoom ?? "" },
                    set: { newValue in
                        if newValue.isEmpty {
                            store.send(.roomSelected(nil))
                        } else if newValue == "___ADD_NEW___" {
                            store.send(.addNewRoomTapped)
                        } else {
                            store.send(.roomSelected(newValue))
                        }
                    }
                )) {
                    Section {
                        Text(.localized(.selectRoom))
                            .tag("")
                        
                        ForEach(store.availableRooms, id: \.self) { room in
                            Text(room).tag(room)
                        }
                    }
                    
                    Section {
                        Label(.localized(.addNewRoom), systemImage: "plus.circle")
                            .tag("___ADD_NEW___")
                    }
                } label: {
                    HStack {
                        Text(store.selectedRoom ?? String.localized(.selectRoom))
                            .foregroundStyle(store.selectedRoom == nil ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
                
                // Icon Grid
                VStack(alignment: .leading, spacing: 6) {
                    Text(.localized(.selectIcon))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 44), spacing: 6)
                    ], spacing: 6) {
                        ForEach(store.availableIcons, id: \.self) { icon in
                            Button {
                                store.send(.iconSelected(icon))
                            } label: { 
                                Image(systemName: icon)
                                    .font(.title)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        store.selectedIcon == icon 
                                            ? Color.secondary.opacity(0.1)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button(.localized(.closeButton), systemImage: "xmark") {
                        store.send(.onCancelButtonTapped)
                    }
                }
            }
        }
        .onTapGesture {
            isFocused = false
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(isPresented: $store.isAddingNewRoom) {
            InsertPasswordAddRoomSheet(store: store)
        }
    }
}

struct InsertPasswordAddRoomSheet: View {
    @Bindable var store: StoreOf<InsertPassword>
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "door.left.hand.open")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 40)

                Text(.localized(.addNewRoom))
                    .font(.title)
                    .fontWeight(.semibold)
                
                TextField(.localized(.roomName), text: $store.newRoomName)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(.capsule)
                    .font(.largeTitle)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                    .overlay(alignment: .leading) {
                        if !store.newRoomName.isEmpty {
                            Button {
                                store.send(.clearNewRoomName)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .padding(12)
                                    .contentShape(Rectangle())
                            }
                            .padding(.leading, 48)
                        }
                    }
                
                Spacer()
                
                Button {
                    store.send(.saveNewRoom)
                } label: {
                    Text(.localized(.save))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.glassProminent)
                .disabled(store.newRoomName.isEmpty)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(.localized(.closeButton), systemImage: "xmark") {
                        store.send(.cancelAddingRoom)
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    InsertPasswordView(store: Store(
        initialState: InsertPassword.State(),
        reducer: { InsertPassword() }
    ))
}
