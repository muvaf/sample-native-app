//
//  PlayView.swift
//  sample-native-app
//
//  Active gameplay: HUD with score + time, and the tappable circle.
//

import SwiftUI

struct PlayView: View {
    @Bindable var model: GameModel

    var body: some View {
        VStack(spacing: 0) {
            HUDView(model: model)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            // The play field. Its size drives circle placement and bounds.
            GeometryReader { proxy in
                ZStack {
                    // A transparent layer so taps outside the circle are ignored
                    // but the field still fills the space.
                    Color.clear

                    CircleView(model: model)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onAppear { model.updatePlayArea(proxy.size) }
                .onChange(of: proxy.size) { _, newSize in
                    model.updatePlayArea(newSize)
                }
            }
        }
    }
}

/// Top bar showing the score and a circular countdown of remaining time.
private struct HUDView: View {
    @Bindable var model: GameModel

    var body: some View {
        HStack(alignment: .center) {
            // Score
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.5))
                Text("\(model.score)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(model.score)))
                    .animation(.snappy, value: model.score)
            }

            Spacer()

            // Countdown ring
            TimeRing(
                fraction: model.timeFraction,
                seconds: model.timeRemaining
            )
            .frame(width: 64, height: 64)
        }
    }
}

/// Circular progress ring that drains as time runs out.
private struct TimeRing: View {
    let fraction: Double
    let seconds: Double

    /// Green → orange → red as time depletes.
    private var ringColor: Color {
        switch fraction {
        case ..<0.25: return Color(red: 0.96, green: 0.30, blue: 0.42)
        case ..<0.5:  return Color(red: 0.98, green: 0.65, blue: 0.16)
        default:      return Color(red: 0.30, green: 0.78, blue: 0.47)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 6)

            Circle()
                .trim(from: 0, to: CGFloat(fraction))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: fraction)

            Text(String(format: "%.1f", max(seconds, 0)))
                .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Time remaining \(String(format: "%.1f", max(seconds, 0))) seconds")
    }
}

/// The tappable circle, animated across position, size and color changes.
private struct CircleView: View {
    @Bindable var model: GameModel

    var body: some View {
        Circle()
            .fill(model.circleColor.gradient)
            .overlay {
                Circle().stroke(.white.opacity(0.25), lineWidth: 2)
            }
            .shadow(color: model.circleColor.opacity(0.5), radius: 18, y: 6)
            .frame(width: model.circleDiameter, height: model.circleDiameter)
            .position(model.circlePosition)
            .onTapGesture {
                model.registerHit()
            }
            .animation(.smooth(duration: 0.28), value: model.circlePosition)
            .animation(.smooth(duration: 0.28), value: model.circleDiameter)
            .animation(.smooth(duration: 0.28), value: model.circleColor)
            .accessibilityIdentifier("speedyCircle")
            .accessibilityLabel("Tap target")
            .accessibilityAddTraits(.isButton)
    }
}
