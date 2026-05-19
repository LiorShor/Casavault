//
//  PasswordsNavigatorView.swift
//  StorePass
//
//  Created by Lior Shor on 22/01/2026.
//

import SwiftUI
import ComposableArchitecture

struct QRScannerSheetForInsert: View {
    let onCodeScanned: (String) -> Void
    @State private var scannedCode: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            QRCodeScannerView(scannedCode: $scannedCode)
                .navigationTitle(.localized(.scanQRCode))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(.localized(.cancel)) {
                            dismiss()
                        }
                    }
                }
                .onChange(of: scannedCode) { _, newValue in
                    if let payload = newValue {
                        onCodeScanned(payload)
                        dismiss()
                    }
                }
        }
    }
}

extension PasswordsNavigator {
    
    struct ContentView: View {
        
        @Bindable var store: StoreOf<PasswordsNavigator>
        
        init(store: StoreOf<PasswordsNavigator>) {
            self.store = store
        }
        
        var body: some View {
            NavigationStack {
                PasswordsCollectionView(
                    store: store.scope(state: \.passwordsCollection, action: \.passwordsCollection)
                )
                .navigationTitle(.localized(.passwords))
                .navigationDestination(item: $store.scope(state: \.passwordDetailNavigator, action: \.passwordDetailNavigator)) { detailNavigatorStore in
                    PasswordDetailNavigatorView(store: detailNavigatorStore)
                }
            }
            .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
                NavigationStack {
                    SettingsView(store: settingsStore)
                }
            }
            .sheet(item: $store.scope(state: \.insertPassword, action: \.insertPassword)) { insertStore in
                NavigationStack {
                    InsertPasswordView(store: insertStore)
                }
                .sheet(isPresented: Binding(
                    get: { store.showingQRScannerForInsert },
                    set: { if !$0 { store.send(.qrScannerForInsertDismissed) } }
                )) {
                    QRScannerSheetForInsert { payload in
                        store.send(.qrCodeScannedForInsert(payload))
                    }
                }
            }
            .sheet(item: $store.scope(state: \.homeKitImport, action: \.homeKitImport)) { homeKitImportStore in
                HomeKitImportView(store: homeKitImportStore)
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

#Preview {
    PasswordsNavigator.ContentView(
        store: Store(
            initialState: PasswordsNavigator.State(),
            reducer: PasswordsNavigator.init
        )
    )
}
