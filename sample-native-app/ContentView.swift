//
//  ContentView.swift
//  sample-native-app
//
//  Speedy Circles — root view that routes between the game phases.
//

import SwiftUI

struct ContentView: View {
    @State private var model = GameModel()

    var body: some View {
        ZStack {
            BackgroundGradient()

            switch model.phase {
            case .start:
                StartView(model: model)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .playing:
                PlayView(model: model)
                    .transition(.opacity)
            case .gameOver:
                GameOverView(model: model)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.smooth(duration: 0.4), value: model.phase)
    }
}

/// A soft full-screen gradient used behind every screen.
private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.07, blue: 0.13),
                Color(red: 0.10, green: 0.12, blue: 0.22),
                Color(red: 0.05, green: 0.06, blue: 0.10),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
