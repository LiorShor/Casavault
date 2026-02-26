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
                Text(.localized(.setupCode))
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
                            .foregroundColor(store.selectedRoom == nil ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
                
                // Icon Picker
                Picker(selection: Binding(
                    get: { store.selectedIcon ?? "" },
                    set: { newValue in
                        if newValue.isEmpty {
                            store.send(.iconSelected(nil))
                        } else {
                            store.send(.iconSelected(newValue))
                        }
                    }
                )) {
                    Text(.localized(.selectIcon))
                        .tag("")
                    
                    ForEach(store.availableIcons, id: \.self) { icon in
                        Label {
                            Text(icon)
                        } icon: {
                            Image(systemName: icon)
                        }
                        .tag(icon)
                    }
                } label: {
                    HStack {
                        if let selectedIcon = store.selectedIcon {
                            Image(systemName: selectedIcon)
                                .foregroundColor(.primary)
                            Text(selectedIcon)
                                .foregroundColor(.primary)
                        } else {
                            Text(.localized(.selectIcon))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
                
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
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(isPresented: $store.isAddingNewRoom) {
            AddRoomSheet(store: store)
        }
    }
}

struct AddRoomSheet: View {
    @Bindable var store: StoreOf<InsertPassword>
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "door.left.hand.open")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue)
                    .padding(.top, 40)
                
                Text(.localized(.addNewRoom))
                    .font(.title)
                    .fontWeight(.semibold)
                
                TextField(.localized(.roomName), text: $store.newRoomName)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                    .font(.largeTitle)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                
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
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized(.cancel)) {
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
