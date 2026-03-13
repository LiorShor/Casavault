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
            Group {
                deviceNameSection
                passwordSection
                roomSection
            }
            
            Group {
                notesSection
                attachmentsSection
                qrCodeScanSection
            }
            
            homeKitBarcodeSection
            
            metadataSection
            
            deleteSection
        }
        .navigationTitle(Text(.localized(.passwordDetails)))
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .toolbar { toolbarContent }
    }
    
    @ViewBuilder
    private var deviceNameSection: some View {
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
    }
    
    @ViewBuilder
    private var passwordSection: some View {
        Section {
                if store.isEditing {
                    HStack {
                        TextField(.localized(.password), text: Binding(
                            get: { store.editedValue },
                            set: { store.send(.view(.valueChanged($0))) }
                        ))
                            .textFieldStyle(.plain)
                            .keyboardType(.numberPad)
                        
                        // Show validation icon only if the value is long enough to potentially be valid
                        if store.editedValue.count >= 8 {
                            Image(systemName: store.isValidPassword ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundStyle(store.isValidPassword ? .green : .red)
                        }
                    }
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
            } footer: {
                if store.isEditing && !store.editedValue.isEmpty && !store.isValidPassword {
                    Text(.localized(.passwordValidationError))
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
    }
    
    @ViewBuilder
    private var roomSection: some View {
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
    }
    
    @ViewBuilder
    private var notesSection: some View {
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
    }
    
    @ViewBuilder
    private var attachmentsSection: some View {
        Section {
                if let attachments = store.password.attachments, !attachments.isEmpty {
                    ForEach(Array(attachments)) { attachment in
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
    }
    
    @ViewBuilder
    private var metadataSection: some View {
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
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
                .disabled(!store.canSave || store.isSaving)
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
    
    @ViewBuilder
    private var qrCodeScanSection: some View {
        if store.isEditing {
            Section {
                Button {
                    store.send(.view(.scanQRCode))
                } label: {
                    Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                }
            } header: {
                Text("Setup Code")
            }
        }
    }
    
    @ViewBuilder
    private var homeKitBarcodeSection: some View {
        if !store.password.value.isEmpty {
            Section {
                HomeKitBarcodeView(
                    code: store.password.value,
                    qrCodePayload: nil
                )
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            } header: {
                Text(.localized(.homeKitSetupCode))
            }
            .listRowBackground(Color.clear)
        }
    }
    
    @ViewBuilder
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                store.send(.view(.onDeleteButtonTapped))
            } label: {
                Text(String.localized(.deleteDevice))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
        }
        .listRowBackground(Color.clear)
    }
}

#Preview {
    let context = CoreDataStack.shared.viewContext
    let password = Password(context: context, name: "iPhone", value: "1234")
    
    return NavigationStack {
        PasswordDetailView(store: Store(
            initialState: PasswordDetail.State(
                password: password
            ),
            reducer: { PasswordDetail() }
        ))
    }
}
