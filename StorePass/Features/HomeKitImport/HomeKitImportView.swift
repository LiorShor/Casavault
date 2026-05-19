//
//  HomeKitImportView.swift
//  StorePass
//
//  Created by Lior Shor on 06/02/2026.
//

import SwiftUI
import ComposableArchitecture

struct HomeKitImportView: View {
    @Bindable var store: StoreOf<HomeKitImport>
    
    var body: some View {
        NavigationStack {
            ZStack {
                if store.isLoading {
                    loadingView
                } else if store.isPermissionDenied {
                    permissionDeniedView
                } else if let error = store.loadingError {
                    errorView(error: error)
                } else {
                    devicesList
                }
            }
            .navigationTitle(Text(.localized(.homeKitImport)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.view(.cancelButtonTapped))
                    } label: {
                        Label(.localized(.cancel), systemImage: "xmark")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.view(.importButtonTapped))
                    } label: {
                        if store.isImporting {
                            ProgressView()
                        } else {
                            Text(.localized(.importButton))
                        }
                    }
                    .disabled(store.selectedDeviceIds.isEmpty || store.isImporting || store.isPermissionDenied)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        store.send(.view(.selectAllButtonTapped))
                    } label: {
                        Text(.localized(store.areAllSelectableDevicesSelected ? .deselectAll : .selectAll))
                    }
                    .disabled(store.devices.isEmpty || store.isLoading || store.isPermissionDenied)
                }
            }
        }
        .onAppear {
            store.send(.view(.onAppear))
        }
        .alert(
            .localized(.deleteDevice),
            isPresented: Binding(
                get: { store.deleteConfirmation != nil },
                set: { if !$0 { store.send(.view(.cancelDelete)) } }
            ),
            actions: {
                Button(.localized(.delete), role: .destructive) {
                    store.send(.view(.confirmDelete))
                }
                
                Button(.localized(.cancel), role: .cancel) {
                    store.send(.view(.cancelDelete))
                }
            },
            message: {
                Text(.localized(.deleteDeviceConfirmation))
            }
        )
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(.localized(.loadingHomeKitDevices))
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text(.localized(.homeKitPermissionDenied))
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(.localized(.homeKitPermissionDeniedDescription))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                store.send(.view(.openSettings))
            } label: {
                Text(.localized(.openSettings))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    @ViewBuilder
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text(.localized(.homeKitLoadError))
                .font(.headline)
            
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                store.send(.view(.retryButtonTapped))
            } label: {
                Text(.localized(.retry))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    @ViewBuilder
    private var devicesList: some View {
        if store.devices.isEmpty {
            emptyStateView
        } else {
            List {
                Section {
                    ForEach(store.devices) { device in
                        let hasPassword = store.existingPasswords.contains(where: { $0.homeKitUniqueIdentifier == device.uniqueIdentifier })
                            || store.existingPasswords.contains(where: { $0.name == device.name })
                        DeviceRow(
                            device: device,
                            isSelected: store.selectedDeviceIds.contains(device.id),
                            hasPassword: hasPassword
                        ) {
                            store.send(.view(.deviceToggled(device.id)))
                        }
                    }
                } header: {
                    Text(.localized(.selectDevicesToImport))
                } footer: {
                    if !store.selectedDeviceIds.isEmpty {
                        Text(.localized(.homeKitImportFooter))
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "homekit")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text(.localized(.noHomeKitDevices))
                .font(.headline)
            
            Text(.localized(.noHomeKitDevicesDescription))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: HomeKitDevice
    let isSelected: Bool
    let hasPassword: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        if let roomName = device.roomName {
                            Text(roomName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(device.categoryType)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeKitImportView(store: Store(
        initialState: HomeKitImport.State(),
        reducer: { HomeKitImport() }
    ))
}
