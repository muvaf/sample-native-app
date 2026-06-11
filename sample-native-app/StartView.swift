//
//  StartView.swift
//  sample-native-app
//
//  The opening screen: title, interval picker and a Start button.
//

import SwiftUI

struct StartView: View {
    @Bindable var model: GameModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            // Title block
            VStack(spacing: 12) {
                Image(systemName: "circle.circle.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.36, green: 0.66, blue: 1.0),
                                     Color(red: 0.62, green: 0.36, blue: 0.96)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .accessibilityHidden(true)

                Text("Speedy Circles")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Tap the circle before time runs out.\nIt shrinks and speeds up every round.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 32)

            // Interval picker
            VStack(spacing: 16) {
                Text("ROUND TIME")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.5))

                HStack(spacing: 12) {
                    ForEach(TimeInterval2.allCases) { interval in
                        IntervalChip(
                            interval: interval,
                            isSelected: model.selectedInterval == interval
                        ) {
                            withAnimation(.snappy(duration: 0.25)) {
                                model.selectInterval(interval)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 32)

            // Start button
            Button {
                model.start()
            } label: {
                Text("Start")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)

            if model.bestScore > 0 {
                Text("Best: \(model.bestScore)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 16)
            }

            Spacer(minLength: 24)
        }
    }
}

/// A single selectable time-interval chip.
private struct IntervalChip: View {
    let interval: TimeInterval2
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(interval.label)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected
                              ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(red: 0.36, green: 0.66, blue: 1.0),
                                             Color(red: 0.62, green: 0.36, blue: 0.96)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                              : AnyShapeStyle(Color.white.opacity(0.08)))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(isSelected ? 0 : 0.12), lineWidth: 1)
                }
                .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(interval.label) round time")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Prominent, full-width primary action button.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.36, green: 0.66, blue: 1.0),
                                     Color(red: 0.62, green: 0.36, blue: 0.96)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(red: 0.36, green: 0.5, blue: 1.0).opacity(0.4),
                            radius: 16, y: 8)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}
