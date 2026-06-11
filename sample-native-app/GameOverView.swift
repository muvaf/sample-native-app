//
//  GameOverView.swift
//  sample-native-app
//
//  Shown when the timer runs out: final score and a Retry button.
//

import SwiftUI

struct GameOverView: View {
    @Bindable var model: GameModel

    private var isNewBest: Bool {
        model.score > 0 && model.score >= model.bestScore
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(Color(red: 0.96, green: 0.30, blue: 0.42))
                .accessibilityHidden(true)

            Text("Time's Up!")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 16)

            // Final score card
            VStack(spacing: 6) {
                Text("FINAL SCORE")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.5))
                Text("\(model.score)")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                if isNewBest {
                    Label("New Best!", systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(red: 0.98, green: 0.65, blue: 0.16))
                        .padding(.top, 2)
                } else if model.bestScore > 0 {
                    Text("Best: \(model.bestScore)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)

            Spacer()

            Button {
                model.reset()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
