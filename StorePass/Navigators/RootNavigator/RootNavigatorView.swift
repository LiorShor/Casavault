//
//  RootNavigatorView.swift
//  StorePass
//
//  Created by Lior Shor on 16/01/2026.
//

import SwiftUI
import ComposableArchitecture
import LocalAuthentication

extension RootNavigator {
    struct ContentView: View {
        @Environment(\.scenePhase) var scenePhase

        public let store: StoreOf<RootNavigator>

        public init(store: StoreOf<RootNavigator>) {
            self.store = store
        }

        public var body: some View {
            Group {
                switch store.destination {
                case .splash:
                    if let store = store.scope(state: \.destination.splash, action: \.destination.splash) {
                        SplashView(store: store)
                    }

                case .home:
                    if let store = store.scope(state: \.destination.home, action: \.destination.home) {
                        HomeNavigator.ContentView(store: store)
                    }
                }
            }
            .animation(.easeInOut, value: store.destination)
            .overlay {
                if store.isLocked {
                    LockScreenView {
                        store.send(.unlockTapped)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: store.isLocked)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                store.send(.scenePhaseChanged(newPhase))
            }
        }
    }
}

private struct LockScreenView: View {
    let onUnlock: () -> Void

    @State private var meshAnimationPhase1 = false
    @State private var meshAnimationPhase2 = false

    private var biometricIconName: String {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType == .faceID ? "faceid" : "touchid"
    }

    var body: some View {
        let points: [SIMD2<Float>] = [
            [0.0, 0.0], [meshAnimationPhase2 ? 0.5 : 1.0, 0.0], [1.0, 0.0],
            [0.0, 0.5], meshAnimationPhase1 ? [0.1, 0.5] : [0.8, 0.2], [1.0, -0.5],
            [0.0, 1.0], [1.0, meshAnimationPhase2 ? 2.0 : 1.0], [1.0, 1.0]
        ]

        let colors: [Color] = [
            meshAnimationPhase2 ? Color("AppBlue") : Color("AppMint"),
            meshAnimationPhase2 ? Color("AppOrange") : Color("AppCyan"),
            meshAnimationPhase1 ? Color("AppCyan") : Color("AppGreen"),
            meshAnimationPhase1 ? Color("AppMint") : Color("AppBlue"),
            meshAnimationPhase2 ? Color("AppGreen") : Color("AppCyan"),
            meshAnimationPhase1 ? Color("AppBlue") : Color("AppTeal"),
            meshAnimationPhase1 ? Color("AppTeal") : Color("AppCyan"),
            meshAnimationPhase2 ? Color("AppMint") : Color("AppBlue"),
            meshAnimationPhase1 ? Color("AppBlue") : Color("AppGreen")
        ]

        return ZStack {
            MeshGradient(width: 3, height: 3, points: points, colors: colors)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .foregroundStyle(.white)

                Text(String.localized(.appName))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Button(action: onUnlock) {
                    Label(String.localized(.unlock), systemImage: biometricIconName)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.25))
                        .clipShape(Capsule())
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                meshAnimationPhase1.toggle()
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                meshAnimationPhase2.toggle()
            }
        }
    }
}

#Preview {
    RootNavigator.ContentView(
        store: Store(
            initialState: RootNavigator.State(),
            reducer: RootNavigator.init
        )
    )
}
