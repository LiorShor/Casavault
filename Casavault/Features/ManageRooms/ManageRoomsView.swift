//
//  ManageRoomsView.swift
//  CasaVault
//

import SwiftUI
import ComposableArchitecture

struct ManageRoomsView: View {
    @Bindable var store: StoreOf<ManageRooms>
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            Group {
                if store.homeId == nil {
                    noHomeView
                } else {
                    List {
                        if !store.rooms.isEmpty {
                            Section {
                                ForEach(store.rooms, id: \.self) { room in
                                    HStack {
                                        Image(systemName: store.roomIcons[room] ?? "door.left.hand.open")
                                            .foregroundStyle(.tint)
                                            .frame(width: 24)
                                        Text(room)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if isEditing {
                                            Button(role: .destructive) {
                                                store.send(.view(.deleteRoom(room)))
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundStyle(.red)
                                            }
                                            .buttonStyle(.borderless)
                                        } else {
                                            Image(systemName: "chevron.forward")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !isEditing {
                                            store.send(.view(.renameTapped(room)))
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            store.send(.view(.deleteRoom(room)))
                                        } label: {
                                            Label(.localized(.delete), systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        Button {
                                            store.send(.view(.renameTapped(room)))
                                        } label: {
                                            Label(.localized(.renameRoom), systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            store.send(.view(.deleteRoom(room)))
                                        } label: {
                                            Label(.localized(.delete), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }

                        Section {
                            Button {
                                store.send(.view(.addRoomTapped))
                            } label: {
                                Label(.localized(.addNewRoom), systemImage: "plus.circle.fill")
                            }

                            Button {
                                store.send(.view(.importFromHomeKitTapped))
                            } label: {
                                if store.isImporting {
                                    HStack {
                                        Label(.localized(.syncRoomsFromHomeKit), systemImage: "house.fill")
                                        Spacer()
                                        ProgressView()
                                    }
                                } else {
                                    Label(.localized(.syncRoomsFromHomeKit), systemImage: "house.fill")
                                }
                            }
                            .disabled(store.isImporting || store.isSyncing)

                            Button {
                                store.send(.view(.syncDeviceRoomsTapped))
                            } label: {
                                if store.isSyncing {
                                    HStack {
                                        Label(.localized(.syncDeviceRooms), systemImage: "arrow.triangle.2.circlepath")
                                        Spacer()
                                        ProgressView()
                                    }
                                } else {
                                    Label(.localized(.syncDeviceRooms), systemImage: "arrow.triangle.2.circlepath")
                                }
                            }
                            .disabled(store.isSyncing || store.isImporting)
                        } header: {
                            Text(.localized(.actions))
                        }
                    }
                }
            }
            .navigationTitle(Text(.localized(.rooms)))
            .toolbar {
                if !store.rooms.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEditing ? .localized(.done) : .localized(.edit)) {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                        .disabled(store.isImporting || store.isSyncing)
                    }
                }
            }
            .task(id: store.homeId) {
                store.send(.view(.onAppear))
            }
            .sheet(item: $store.scope(state: \.renameSheet, action: \.renameSheet)) { renameStore in
                RenameRoomSheetView(store: renameStore)
            }
            .sheet(item: $store.scope(state: \.addRoomSheet, action: \.addRoomSheet)) { addStore in
                AddRoomSheetView(store: addStore)
            }
        }
    }

    private var noHomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(.secondary)

            Text(.localized(.noHomeSelected))
                .font(.title2)
                .fontWeight(.semibold)

            Text(.localized(.noHomeSelectedMessage))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
