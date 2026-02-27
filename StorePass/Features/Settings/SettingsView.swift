//
//  SettingsView.swift
//  StorePass
//
//  Created by Lior Shor on 25/01/2026.
//

import SwiftUI
import ComposableArchitecture
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var store: StoreOf<Settings>
    
    private var currentLanguage: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return languageCode == "he" ? String.localized(.languageHebrew) : String.localized(.languageEnglish)
    }

    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                Section {
                    Picker(selection: $store.selectedTheme.sending(\.view.themeChanged)) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName)
                                .tag(theme)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundStyle(.secondary)
                            Text(.localized(.appearance))
                        }
                    }
                } header: {
                    Text(.localized(.appearance))
                }
                
                // General Section
                Section {
                    Button {
                        store.send(.view(.onOpenLanguageSettingsButtonTapped))
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text(.localized(.language))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text(currentLanguage)
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "chevron.forward")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text(.localized(.general))
                } footer: {
                    Text(.localized(.languageSettingsFooter))
                        .font(.caption)
                }
                
                // Data Section
                Section {
                    Button {
                        store.send(.view(.onImportFromHomeKitButtonTapped))
                    } label: {
                        HStack {
                            Image(systemName: "homekit")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text(.localized(.homeKitImport))
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    Button {
                        store.send(.view(.onExportButtonTapped))
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text(.localized(.exportPasswords))
                                .foregroundStyle(.primary)
                            
                            if store.isExportingPasswords {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                    .disabled(store.isExportingPasswords)
                } header: {
                    Text(.localized(.data))
                }
            }
            .navigationTitle(Text(.localized(.settings)))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.view(.onDismiss))
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(item: $store.scope(state: \.shareSheet, action: \.shareSheet)) { _ in
                if let shareSheetState = store.shareSheet {
                    ShareSheet(items: [shareSheetState.fileURL])
                }
            }
            .sheet(item: $store.scope(state: \.homeKitImport, action: \.homeKitImport)) { homeKitImportStore in
                HomeKitImportView(store: homeKitImportStore)
            }
        }
    }
}

// ShareSheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView(store: Store(
        initialState: Settings.State(selectedTheme: .system),
        reducer: { Settings() }
    ))
}
