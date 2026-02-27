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
                    TextField(.localized(.password), text: $store.editedValue.sending(\.view.valueChanged))
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
            
            // Notes Section
            Section {
                if store.isEditing {
                    TextEditor(text: $store.editedNotes.sending(\.view.notesChanged))
                        .frame(minHeight: 100)
                } else {
                    if let notes = store.password.notes, !notes.isEmpty {
                        Text(notes)
                    } else {
                        Text(.localized(.noNotes))
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text(.localized(.notes))
            }
            
            // Attachments Section
            Section {
                if let attachments = store.password.attachments, !attachments.isEmpty {
                    ForEach(attachments) { attachment in
                        Button {
                            store.send(.view(.viewAttachment(attachment)))
                        } label: {
                            HStack {
                                if let imageData = attachment.imageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(attachment.fileName)
                                        .foregroundStyle(.primary)
                                    Text(attachment.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.send(.view(.deleteAttachment(attachment)))
                            } label: {
                                Label(.localized(.delete), systemImage: "trash")
                            }
                        }
                    }
                } else {
                    Text(.localized(.noAttachments))
                        .foregroundStyle(.tertiary)
                }
                
                if store.isEditing {
                    Menu {
                        Button {
                            store.send(.view(.addAttachmentFromCamera))
                        } label: {
                            Label(.localized(.takePhoto), systemImage: "camera")
                        }
                        
                        Button {
                            store.send(.view(.addAttachmentFromLibrary))
                        } label: {
                            Label(.localized(.chooseFromLibrary), systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Label(.localized(.addAttachment), systemImage: "plus.circle")
                    }
                    .compositingGroup()
                }
            } header: {
                Text(.localized(.attachments))
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
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .toolbar {
            if store.isEditing {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.view(.onSaveButtonTapped))
                    } label: {
                        if store.isSaving {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .disabled(store.editedName.isEmpty || store.editedValue.isEmpty || store.isSaving)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.view(.onCancelButtonTapped))
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            } else {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.view(.onEditButtonTapped))
                    } label: {
                        Text(.localized(.edit))
                    }
                }
            }
        }
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
