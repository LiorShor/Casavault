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
