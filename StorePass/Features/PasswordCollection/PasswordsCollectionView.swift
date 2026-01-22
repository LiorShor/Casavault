//
//  DeviceCollectionView.swift
//  StorePass
//
//  Created by Lior Shor on 11/07/2025.
//

import SwiftUI
import SwiftData
import ComposableArchitecture


struct PasswordsCollectionView: View {
    
    let store: StoreOf<PasswordsCollection>
    init(store: StoreOf<PasswordsCollection>) {
        self.store = store
    }

    
    var body: some View {
        List {
            ForEach(store.passwords) { password in
                Button {
                    store.send(.view(.onPasswordTap(password)))
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(password.name)
                            .font(.headline)
                        Text(password.createdAt, format: Date.FormatStyle(date: .numeric, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let password = store.passwords[index]
                    store.send(.view(.onDeletePassword(password)))
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    store.send(.view(.onAddPassword))
                } label: {
                    Label(.addPassword, systemImage: "plus")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PasswordsCollectionView(
            store: Store(
                initialState: PasswordsCollection.State(passwords: []),
                reducer: { PasswordsCollection() }
            )
        )
    }
}
