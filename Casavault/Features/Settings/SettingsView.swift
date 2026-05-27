//
//  SettingsView.swift
//  CasaVault
//
//  Created by Lior Shor on 25/01/2026.
//

import SwiftUI
import ComposableArchitecture
import UniformTypeIdentifiers
import LocalAuthentication

struct SettingsView: View {
    @Bindable var store: StoreOf<Settings>

    private var currentLanguage: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return languageCode == "he" ? String.localized(.languageHebrew) : String.localized(.languageEnglish)
    }

    private var canUseBiometrics: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    private var biometricIconName: String {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType == .faceID ? "faceid" : "touchid"
    }

    private var biometricLockTitle: LocalizedStringKey {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType == .faceID ? .localized(.biometricLockFaceID) : .localized(.biometricLockTouchID)
    }

    var body: some View {
        NavigationStack {
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
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            Text(.localized(.appearance))
                        }
                    }
                    .id(store.accentColorName)

                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 24)
                        Text(.localized(.accentColor))
                            .foregroundStyle(.primary)

                        Spacer()

                        HStack(spacing: 10) {
                            ForEach(Color.AppColor.allCases, id: \.self) { appColor in
                                Button {
                                    store.send(.view(.colorChanged(appColor)))
                                } label: {
                                    Circle()
                                        .fill(appColor.color)
                                        .frame(width: 26, height: 26)
                                        .overlay {
                                            if store.accentColorName == appColor.rawValue {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(appColor.checkmarkColor)
                                            }
                                        }
                                        .overlay {
                                            Circle()
                                                .strokeBorder(Color.primary.opacity(appColor == .monochrome ? 0.2 : 0), lineWidth: 1)
                                        }
                                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(.plain)
                            }
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
                                .foregroundStyle(Color.accentColor)
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
                        store.send(.view(.onExportButtonTapped))
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.accentColor)
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
                
                // Security Section
                if canUseBiometrics {
                    Section {
                        Toggle(isOn: Binding(
                            get: { store.isBiometricLockEnabled },
                            set: { store.send(.view(.biometricLockToggled($0))) }
                        )) {
                            HStack {
                                Image(systemName: biometricIconName)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24)
                                Text(biometricLockTitle)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .tint(Color.AppColor(rawValue: store.accentColorName)?.toggleTintColor ?? Color.appAccentColor(named: store.accentColorName))
                    } header: {
                        Text(.localized(.security))
                    } footer: {
                        Text(.localized(.biometricLockDescription))
                            .font(.caption)
                    }
                }

                // Support Section
                Section {
                    Button {
                        store.send(.view(.onRateAppButtonTapped))
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .frame(width: 24)
                            Text(.localized(.rateApp))
                                .foregroundStyle(.primary)
                        }
                    }
                    Button {
                        store.send(.view(.onContactButtonTapped))
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            Text(.localized(.contactUs))
                                .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text(.localized(.support))
                }
            }
            .navigationTitle(Text(.localized(.settings)))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.view(.onDismiss))
                    } label: {
                        Label(.localized(.closeButton), systemImage: "xmark")
                    }
                }
            }
            .sheet(item: $store.scope(state: \.shareSheet, action: \.shareSheet)) { _ in
                if let shareSheetState = store.shareSheet {
                    ShareSheet(items: [shareSheetState.fileURL])
                }
            }
        }
        .tint(Color.appAccentColor(named: store.accentColorName))
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
