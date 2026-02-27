//
//  PasswordDetailView.swift
//  StorePass
//
//  Created by Lior Shor on 05/02/2026.
//

import SwiftUI
import ComposableArchitecture

struct PasswordDetailView: View {
    @Bindable var store: StoreOf<PasswordDetail>
    
    var body: some View {
        List {
            // Password Name Section
            Section {
                if store.isEditing {
                    TextField(.localized(.deviceName), text: $store.editedName.sending(\.view.nameChanged))
                        .textFieldStyle(.plain)
                } else {
                    HStack {
                        Text(.localized(.deviceName))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(store.password.name)
                    }
                }
            } header: {
                Text(.localized(.device))
            }
            
            // Password Value Section
            Section {
                if store.isEditing {
                    SecureField(.localized(.password), text: $store.editedValue.sending(\.view.valueChanged))
                        .textFieldStyle(.plain)
                } else {
                    HStack {
                        Text(.localized(.password))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(store.password.value)
                            .fontDesign(.monospaced)
                    }
                }
            } header: {
                Text(.localized(.password))
            }
            
            // Room Section
            Section {
                if store.isEditing {
                    Picker(selection: Binding(
                        get: { store.editedRoom ?? "" },
                        set: { newValue in
                            if newValue.isEmpty {
                                store.send(.view(.roomSelected(nil)))
                            } else if newValue == "___ADD_NEW___" {
                                store.send(.view(.addNewRoomTapped))
                            } else {
                                store.send(.view(.roomSelected(newValue)))
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
                        Text(.localized(.room))
                    }
                    .pickerStyle(.menu)
                } else {
                    HStack {
                        Text(.localized(.room))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let room = store.password.room {
                            Text(room)
                        } else {
                            Text(.localized(.noRoom))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            } header: {
                Text(.localized(.room))
            }
            
            // Metadata Section
            Section {
                HStack {
                    Text(.localized(.created))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(store.password.createdAt, style: .date)
                        .foregroundStyle(.secondary)
                }
                
                if let updatedAt = store.password.updatedAt {
                    HStack {
                        Text(.localized(.lastUpdated))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(updatedAt, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(.localized(.information))
            }
        }
        .navigationTitle(Text(.passwordDetails))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.isEditing {
                    HStack(spacing: 8) {
                        Button {
                            store.send(.view(.onCancelButtonTapped))
                        } label: {
                            Text(.localized(.cancel))
                        }
                        
                        Button {
                            store.send(.view(.onSaveButtonTapped))
                        } label: {
                            if store.isSaving {
                                ProgressView()
                            } else {
                                Text(.localized(.save))
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(store.editedName.isEmpty || store.editedValue.isEmpty || store.isSaving)
                    }
                } else {
                    Button {
                        store.send(.view(.onEditButtonTapped))
                    } label: {
                        Text(.localized(.edit))
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.isAddingNewRoom },
            set: { if !$0 { store.send(.view(.cancelAddingRoom)) } }
        )) {
            AddRoomSheetPasswordDetail(store: store)
        }
    }
}

struct AddRoomSheetPasswordDetail: View {
    @Bindable var store: StoreOf<PasswordDetail>
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
                
                TextField(.localized(.roomName), text: Binding(
                    get: { store.newRoomName },
                    set: { store.send(.view(.newRoomNameChanged($0))) }
                ))
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                    .font(.largeTitle)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                    .overlay(alignment: .leading) {
                        if !store.newRoomName.isEmpty {
                            Button {
                                store.send(.view(.clearNewRoomName))
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
                    store.send(.view(.saveNewRoom))
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
                    Button {
                        store.send(.view(.cancelAddingRoom))
                    } label: {
                        Image(systemName: "xmark")
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
    NavigationStack {
        PasswordDetailView(store: Store(
            initialState: PasswordDetail.State(
                password: Password(name: "iPhone", value: "1234")
            ),
            reducer: { PasswordDetail() }
        ))
    }
}
