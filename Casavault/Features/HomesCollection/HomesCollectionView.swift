//
//  HomesCollectionView.swift
//  CasaVault
//
//  Created by Lior Shor on 26/02/2026.
//

import SwiftUI
import ComposableArchitecture

extension HomesCollection {
    
    struct ContentView: View {
        
        @Bindable var store: StoreOf<HomesCollection>
        
        init(store: StoreOf<HomesCollection>) {
            self.store = store
        }
        
        var body: some View {
            NavigationStack {
                List {
                    Section {
                        ForEach(store.homes) { home in
                            HomeRow(
                                home: home,
                                isDefault: home.id == store.defaultHomeId,
                                onToggleDefault: {
                                    store.send(.view(.toggleDefaultHome(home)))
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.send(.view(.onDeleteHome(home)))
                                } label: {
                                    Label(.localized(.delete), systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.send(.view(.onDeleteHome(home)))
                                } label: {
                                    Label(.localized(.delete), systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text(.localized(.myHomes))
                    } footer: {
                        if store.homes.isEmpty {
                            Text(.localized(.noHomesYetMessage))
                                .font(.caption)
                        } else {
                            Text(.localized(.homesFooter))
                                .font(.caption)
                        }
                    }
                    
                    Section {
                        Button {
                            store.send(.view(.onAddHomeButtonTapped))
                        } label: {
                            Label(.localized(.addNewHome), systemImage: "plus.circle.fill")
                        }
                        
                        Button {
                            store.send(.view(.onImportFromHomeKitTapped))
                        } label: {
                            if store.isImporting {
                                HStack {
                                    Label(.localized(.importFromHomeKit), systemImage: "house.fill")
                                    Spacer()
                                    ProgressView()
                                }
                            } else {
                                Label(.localized(.importFromHomeKit), systemImage: "house.fill")
                            }
                        }
                        .disabled(store.isImporting)
                    } header: {
                        Text(.localized(.actions))
                    }
                }
                .navigationTitle(.localized(.homes))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            store.send(.view(.onSettingsButtonTapped))
                        } label: {
                            Label(.localized(.settings), systemImage: "gear")
                        }
                    }
                }
                .sheet(isPresented: $store.isAddingNewHome) {
                    AddHomeSheet(store: store)
                }
                .alert(
                    .localized(.homeKitPermissionDenied),
                    isPresented: $store.showPermissionDeniedAlert,
                    actions: {
                        Button(.localized(.openSettings)) {
                            store.send(.view(.openSettings))
                        }
                        Button(.localized(.cancel), role: .cancel) {}
                    },
                    message: {
                        Text(.localized(.homeKitPermissionDeniedDescription))
                    }
                )
            }
        }
    }
}

struct HomeRow: View {
    let home: Home
    let isDefault: Bool
    let onToggleDefault: () -> Void

    var body: some View {
        Button(action: onToggleDefault) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(home.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if home.homeKitUniqueIdentifier != nil {
                        Label(.localized(.fromHomeKit), systemImage: "house.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isDefault ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isDefault ? .green : .secondary)
                    .imageScale(.large)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let context = CoreDataStack.shared.viewContext
    let home1 = Home(context: context, name: "My Home", isDefault: true)
    let home2 = Home(context: context, name: "Office", isDefault: false)
    let home3 = Home(context: context, name: "Vacation Home", isDefault: false, homeKitUniqueIdentifier: UUID())
    
    let state = HomesCollection.State(homes: [home1, home2, home3])
    return HomesCollection.ContentView(
        store: Store(
            initialState: state,
            reducer: HomesCollection.init
        )
    )
}
struct AddHomeSheet: View {
    @Bindable var store: StoreOf<HomesCollection>
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "house.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 40)

                Text(.localized(.addNewHome))
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(.localized(.enterHomeName))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField(.localized(.homeName), text: $store.newHomeName)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .clipShape(.capsule)
                    .focused($isTextFieldFocused)
                    .overlay(alignment: .trailing) {
                        if !store.newHomeName.isEmpty {
                            Image(systemName: store.homeNameExists ? "xmark.circle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(store.homeNameExists ? .red : .green)
                                .padding(.trailing, 20)
                        }
                    }
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button {
                    store.send(.view(.saveNewHome))
                } label: {
                    Text(.localized(.save))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.glassProminent)
                .disabled(!store.isHomeNameValid)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.view(.cancelAddingHome))
                    } label: {
                        Label(.localized(.closeButton), systemImage: "xmark")
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

