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
    
    init(store: StoreOf<Splash>) {
        self.store = store
    }
    
    var body: some View {
        ZStack {
            Image(".splashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .foregroundStyle(".background")
        .onAppear { send(.onAppear) }
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
