//
//  DeviceCollectionView.swift
//  StorePass
//
//  Created by Lior Shor on 11/07/2025.
//

import SwiftUI
import SwiftData
import ComposableArchitecture
import UniformTypeIdentifiers
import CoreData


struct PasswordsCollectionView: View {

    let store: StoreOf<PasswordsCollection>
    @State private var coreDataSaveCount = 0

    init(store: StoreOf<PasswordsCollection>) {
        self.store = store
    }


    var body: some View {
        Group {
            if store.hasNoHome {
                noHomeView
            } else if store.viewMode == .list {
                listView
            } else {
                gridView
            }
        }
        .id(coreDataSaveCount)
        .onReceive(NotificationCenter.default.publisher(for: NSManagedObjectContext.didSaveObjectsNotification)) { notification in
            // Only refresh on insert/update — not on delete.
            // Deleted NSManagedObjects become faults after save; accessing .id on them crashes.
            // Deletion is handled by PasswordsNavigator reloading state on dismiss.
            let hasInsertedOrUpdated = [NSUpdatedObjectsKey, NSInsertedObjectsKey].contains { key in
                (notification.userInfo?[key] as? Set<NSManagedObject>)?.contains { $0 is Password } == true
            }
            if hasInsertedOrUpdated {
                coreDataSaveCount += 1
            }
        }
        .searchable(
            text: Binding(
                get: { store.searchText },
                set: { store.send(.view(.searchTextChanged($0))) }
            ),
            prompt: Text(.localized(.searchPasswords))
        )
        .onAppear {
            store.send(.view(.onAppear))
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.view(.onSettingsButtonTapped))
                } label: {
                    Label(.localized(.settings), systemImage: "gear")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Edit Mode Section
                    Button {
                        store.send(.view(.toggleEditMode))
                    } label: {
                        Label(
                            store.isEditMode ? String.localized(.done) : String.localized(.edit),
                            systemImage: store.isEditMode ? "checkmark" : "pencil.line"
                        )
                    }
                    .disabled(store.hasNoHome)
                    
                    Divider()
                    
                    // Home Selection Section
                    if !store.availableHomes.isEmpty {
                        Picker(selection: Binding(
                            get: { store.currentHomeId ?? UUID() },
                            set: { store.send(.view(.homeSelected($0))) }
                        )) {
                            ForEach(store.availableHomes) { home in
                                Text(home.name).tag(home.id)
                            }
                        } label: {
                            Label(.localized(.selectHome), systemImage: "house")
                        }
                        
                        Divider()
                    }
                    
                    // Grouping Section
                    Picker(selection: Binding(
                        get: { store.groupingMode },
                        set: { store.send(.view(.groupingModeChanged($0))) }
                    )) {
                        ForEach(PasswordGroupingMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    } label: {
                        Label(.localized(.grouping), systemImage: "folder")
                    }
                    
                    Divider()
                    
                    // View Mode Section
                    Button {
                        store.send(.view(.toggleViewMode))
                    } label: {
                        Label(
                            store.viewMode == .list ? String.localized(.gridView) : String.localized(.listView),
                            systemImage: store.viewMode == .list ? "square.grid.2x2" : "list.bullet"
                        )
                    }

                } label: {
                    Label(.localized(.options), systemImage: "ellipsis")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        store.send(.view(.onAddPasswordButtonTapped))
                    } label: {
                        Label(.localized(.addNewDevice), systemImage: "plus.circle")
                    }
                    
                    Button {
                        store.send(.view(.onImportFromHomeKitButtonTapped))
                    } label: {
                        Label(.localized(.importFromSmartHome), systemImage: "homekit")
                    }
                } label: {
                    Label(.localized(.addPassword), systemImage: "plus")
                }
                .disabled(store.hasNoHome)
            }
        }
    }
    
    @ViewBuilder
    private var listView: some View {
        List {
            if !store.availableRooms.isEmpty || !store.availableDeviceTypes.isEmpty {
                filterBarView
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            ForEach(store.sortedRoomNames, id: \.self) { roomName in
                Section(header: store.groupingMode == .byRoom ? Text(roomName) : nil) {
                    ForEach(store.groupedPasswords[roomName] ?? []) { password in
                        PasswordListRow(password: password, pendingRoomDeletions: store.pendingRoomDeletions) {
                            if !store.isEditMode {
                                store.send(.view(.onPasswordTap(password)))
                            }
                        }
                    }
                    .onMove { indices, destination in
                        store.send(.view(.movePassword(indices, destination, roomName)))
                    }
                    .onDelete { indexSet in
                        let passwordsInRoom = store.groupedPasswords[roomName] ?? []
                        for index in indexSet {
                            store.send(.view(.onDeletePassword(passwordsInRoom[index])))
                        }
                    }
                }
            }
        }
        .environment(\.editMode, .constant(store.isEditMode ? .active : .inactive))
    }
    
    @ViewBuilder
    private var gridView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                if !store.availableRooms.isEmpty || !store.availableDeviceTypes.isEmpty {
                    filterBarView
                        .padding(.horizontal, -16)
                }
                ForEach(store.sortedRoomNames, id: \.self) { roomName in
                    Section {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 80), spacing: 12)
                        ], spacing: 12) {
                            ForEach(store.groupedPasswords[roomName] ?? []) { password in
                                PasswordGridCard(
                                    password: password,
                                    isEditMode: store.isEditMode,
                                    isDragging: store.draggingPassword?.id == password.id,
                                    pendingRoomDeletions: store.pendingRoomDeletions
                                ) {
                                    if !store.isEditMode {
                                        store.send(.view(.onPasswordTap(password)))
                                    }
                                } onDelete: {
                                    store.send(.view(.onDeletePassword(password)))
                                }
                                .onLongPressGesture(minimumDuration: 0.5) {
                                    if !store.isEditMode {
                                        store.send(.view(.toggleEditMode))
                                    }
                                }
                                .onDrag {
                                    if store.isEditMode {
                                        store.send(.view(.startDragging(password)))
                                    }
                                    return NSItemProvider(object: password.id.uuidString as NSString)
                                }
                                .onDrop(of: [.text], delegate: PasswordDropDelegate(
                                    password: password,
                                    roomName: roomName,
                                    isEditMode: store.isEditMode,
                                    onDrop: { sourceId in
                                        store.send(.view(.endDragging))
                                        if let sourcePassword = store.passwords.first(where: { $0.id.uuidString == sourceId }) {
                                            store.send(.view(.gridMovePassword(sourcePassword, password, roomName)))
                                        }
                                    }
                                ))
                            }
                        }
                    } header: {
                        if store.groupingMode == .byRoom {
                            Text(roomName)
                                .font(.headline)
                                .padding(.horizontal)
                                .glassEffect()
                                .padding(.top, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            if !store.isEditMode {
                store.send(.view(.toggleEditMode))
            }
        }
        .onTapGesture {
            if store.isEditMode {
                store.send(.view(.toggleEditMode))
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String?
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    @AppStorage("accentColorName") private var accentColorName = Color.AppColor.blue.rawValue

    private var selectedForegroundColor: Color {
        Color.AppColor(rawValue: accentColorName)?.checkmarkColor ?? .white
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline)
                }
                if let label {
                    Text(label)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? selectedForegroundColor : Color.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - List Row

struct PasswordListRow: View {
    let password: Password
    var pendingRoomDeletions: Set<String> = []
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon
                if let icon = password.icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(password.name)
                        .font(.subheadline)

                    if let room = password.room, !pendingRoomDeletions.contains(room) {
                        Text(room)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Show warning icon if password is empty
                if password.value.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
            }
        }
    }
}

// MARK: - Grid Card

struct PasswordGridCard: View {
    let password: Password
    let isEditMode: Bool
    let isDragging: Bool
    var pendingRoomDeletions: Set<String> = []
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var wiggleAngle: Double = 0
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .strokeBorder(Color.accentColor, lineWidth: 1)
                        
                        // Warning icon overlay (only when not in edit mode)
                        if password.value.isEmpty && !isEditMode {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                                .padding(8)
                        }
                    }
                    .frame(height: 100)
                    .overlay(
                        VStack(spacing: 8) {
                            if let icon = password.icon {
                                Image(systemName: icon)
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.accentColor)
                            }
                            Text(password.name)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                        }
                        .padding(8)
                    )

                    if let room = password.room, !pendingRoomDeletions.contains(room) {
                        Text(room)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                
                // Delete button in edit mode
                if isEditMode {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red, Color(.systemGray5))
                    }
                    .offset(x: 15, y: -15)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(isDragging ? 0.5 : 1.0)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .rotationEffect(.degrees(wiggleAngle))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .task(id: isEditMode) {
            if isEditMode {
                // Small random delay for staggered effect
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0...100_000_000)))

                // Continuous wiggle animation
                while !Task.isCancelled && isEditMode {
                    await wiggle()
                }
            }
            // Always reset — runs whether edit mode ended normally or task was cancelled mid-wiggle
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                wiggleAngle = 0
            }
        }
    }

    private func wiggle() async {
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 0.1)) {
            wiggleAngle = -1.5
        }
        try? await Task.sleep(nanoseconds: 100_000_000)

        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 0.1)) {
            wiggleAngle = 1.5
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}

// MARK: - Drop Delegate

struct PasswordDropDelegate: DropDelegate {
    let password: Password
    let roomName: String
    let isEditMode: Bool
    let onDrop: (String) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard isEditMode else { return false }
        
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            if let data = data as? Data,
               let sourceId = String(data: data, encoding: .utf8) {
                Task { @MainActor in
                    onDrop(sourceId)
                }
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Optional: Add visual feedback
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: isEditMode ? .move : .cancel)
    }
}

extension PasswordsCollectionView {
    @ViewBuilder
    var filterBarView: some View {
        let hasFilters = !store.availableRooms.isEmpty || !store.availableDeviceTypes.isEmpty
        if hasFilters {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: String.localized(.filterAll),
                        systemImage: nil,
                        isSelected: store.selectedFilter == nil
                    ) {
                        store.send(.view(.filterChanged(nil)))
                    }

                    if !store.availableRooms.isEmpty {
                        Divider().frame(height: 20)
                        ForEach(store.availableRooms, id: \.self) { room in
                            FilterChip(
                                label: room,
                                systemImage: store.roomIcons[room] ?? "door.left.hand.open",
                                isSelected: store.selectedFilter == .room(room)
                            ) {
                                store.send(.view(.filterChanged(.room(room))))
                            }
                        }
                    }

                    if !store.availableDeviceTypes.isEmpty {
                        Divider().frame(height: 20)
                        ForEach(store.availableDeviceTypes, id: \.self) { icon in
                            FilterChip(
                                label: nil,
                                systemImage: icon,
                                isSelected: store.selectedFilter == .deviceType(icon)
                            ) {
                                store.send(.view(.filterChanged(.deviceType(icon))))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private var noHomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.secondary)
            
            Text(.localized(.noHomeSelected))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(.localized(.noHomeSelectedMessage))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                store.send(.navigation(.navigateToHomes))
            } label: {
                Text(.localized(.goToHomes))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.glassProminent)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
