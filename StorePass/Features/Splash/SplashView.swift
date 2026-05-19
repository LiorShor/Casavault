//
//  SplashView.swift
//  StorePass
//
//  Created by Lior Shor on 15/01/2026.
//

import SwiftUI
import ComposableArchitecture

@ViewAction(for: Splash.self)
struct SplashView: View {
    
    let store: StoreOf<Splash>
    @State private var meshAnimationPhase1 = false
    @State private var meshAnimationPhase2 = false
    
    init(store: StoreOf<Splash>) {
        self.store = store
    }
    
    var body: some View {
        let points: [SIMD2<Float>] = [
            [0.0, 0.0], [meshAnimationPhase2 ? 0.5 : 1.0, 0.0], [1.0, 0.0],
            [0.0, 0.5], meshAnimationPhase1 ? [0.1, 0.5] : [0.8, 0.2], [1.0, -0.5],
            [0.0, 1.0], [1.0, meshAnimationPhase2 ? 2.0 : 1.0], [1.0, 1.0]
        ]
        
        let colors: [Color] = [
            meshAnimationPhase2 ? Color.appBlue : Color.appMint,
            meshAnimationPhase2 ? Color.appOrange : Color.appCyan,
            meshAnimationPhase1 ? Color.appCyan : Color.appGreen,
            meshAnimationPhase1 ? Color.appMint : Color.appBlue,
            meshAnimationPhase2 ? Color.appGreen : Color.appCyan,
            meshAnimationPhase1 ? Color.appBlue : Color.appTeal,
            meshAnimationPhase1 ? Color.appTeal : Color.appCyan,
            meshAnimationPhase2 ? Color.appMint : Color.appBlue,
            meshAnimationPhase1 ? Color.appBlue : Color.appGreen
        ]
        
        return ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: points,
                colors: colors
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "key.horizontal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.white)
                
                Text(.localized(.appName))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                meshAnimationPhase1.toggle()
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                meshAnimationPhase2.toggle()
            }
            
            Task {
                try? await Task.sleep(for: .seconds(5))
                send(.onAppear)
            }
        }
    }
}

#Preview {
    SplashView(
        store: Store(
            initialState: Splash.State(),
            reducer: Splash.init
        )
    )
}
