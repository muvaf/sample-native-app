//
//  GameModel.swift
//  sample-native-app
//
//  Speedy Circles — game state, countdown and spawn logic.
//

import SwiftUI

/// The phases the game moves through.
enum GamePhase {
    case start
    case playing
    case gameOver
}

/// A selectable round duration shown on the start screen.
enum TimeInterval2: Double, CaseIterable, Identifiable {
    case fast = 2.0
    case medium = 3.0
    case slow = 5.0

    var id: Double { rawValue }

    /// Short label such as "2.0s".
    var label: String { String(format: "%.1fs", rawValue) }
}

@MainActor
@Observable
final class GameModel {

    // MARK: - Tunables

    /// Diameter of the very first circle of a run.
    static let maxDiameter: CGFloat = 170
    /// Smallest the circle is ever allowed to get.
    static let minDiameter: CGFloat = 56
    /// Fraction the diameter keeps after every successful tap.
    static let shrinkFactor: CGFloat = 0.86

    /// Pleasant, high-contrast circle colors.
    static let palette: [Color] = [
        Color(red: 0.20, green: 0.55, blue: 0.98), // blue
        Color(red: 0.96, green: 0.30, blue: 0.42), // red/pink
        Color(red: 0.30, green: 0.78, blue: 0.47), // green
        Color(red: 0.98, green: 0.65, blue: 0.16), // orange
        Color(red: 0.62, green: 0.36, blue: 0.96), // purple
        Color(red: 0.18, green: 0.74, blue: 0.80), // teal
    ]

    // MARK: - Observed state

    private(set) var phase: GamePhase = .start
    var selectedInterval: TimeInterval2 = .medium

    private(set) var score: Int = 0
    private(set) var bestScore: Int = 0

    private(set) var circleDiameter: CGFloat = maxDiameter
    private(set) var circlePosition: CGPoint = .zero
    private(set) var circleColor: Color = palette[0]

    /// Seconds left in the current round, kept fresh for smooth display.
    private(set) var timeRemaining: Double = 0

    // MARK: - Private

    /// Size of the area the circle may occupy, supplied by the play view.
    private var playSize: CGSize = .zero
    private var deadline: Date = .distantFuture
    private var timer: Timer?
    private var colorIndex: Int = 0
    private var hasSpawned = false

    /// Fraction of the round still remaining, 0...1, for the countdown ring.
    var timeFraction: Double {
        let total = selectedInterval.rawValue
        guard total > 0 else { return 0 }
        return min(max(timeRemaining / total, 0), 1)
    }

    // MARK: - Lifecycle

    /// Called by the play view once it knows its size. The first call kicks
    /// off the opening round; later calls (e.g. rotation) just update bounds.
    func updatePlayArea(_ size: CGSize) {
        playSize = size
        guard phase == .playing else { return }
        if !hasSpawned {
            hasSpawned = true
            spawn(initial: true)
            startTimer()
        } else {
            // Keep the existing circle on-screen after a size change.
            circlePosition = clampedPosition(circlePosition, diameter: circleDiameter)
        }
    }

    func selectInterval(_ interval: TimeInterval2) {
        selectedInterval = interval
    }

    /// Begin a fresh run from the start screen.
    func start() {
        score = 0
        circleDiameter = Self.maxDiameter
        colorIndex = Int.random(in: 0..<Self.palette.count)
        circleColor = Self.palette[colorIndex]
        timeRemaining = selectedInterval.rawValue
        hasSpawned = false
        phase = .playing
        // If we already know our bounds (e.g. retry without a layout change),
        // spawn immediately; otherwise updatePlayArea will do it.
        if playSize.width > 0, playSize.height > 0 {
            hasSpawned = true
            spawn(initial: true)
            startTimer()
        }
    }

    /// The player tapped the circle in time.
    func registerHit() {
        guard phase == .playing else { return }
        score += 1
        circleDiameter = max(Self.minDiameter, circleDiameter * Self.shrinkFactor)
        spawn(initial: false)
        resetCountdown()
    }

    /// Return to the start screen.
    func reset() {
        stopTimer()
        phase = .start
        hasSpawned = false
        timeRemaining = selectedInterval.rawValue
    }

    // MARK: - Spawning

    private func spawn(initial: Bool) {
        // Advance to a different color than the current one.
        if !initial {
            var next = colorIndex
            while next == colorIndex { next = Int.random(in: 0..<Self.palette.count) }
            colorIndex = next
        }
        circleColor = Self.palette[colorIndex]
        circlePosition = randomPosition(diameter: circleDiameter)
    }

    private func randomPosition(diameter: CGFloat) -> CGPoint {
        let radius = diameter / 2
        guard playSize.width > diameter, playSize.height > diameter else {
            return CGPoint(x: playSize.width / 2, y: playSize.height / 2)
        }
        let x = CGFloat.random(in: radius...(playSize.width - radius))
        let y = CGFloat.random(in: radius...(playSize.height - radius))
        return CGPoint(x: x, y: y)
    }

    /// Clamp a point so a circle of the given diameter stays fully in bounds.
    private func clampedPosition(_ point: CGPoint, diameter: CGFloat) -> CGPoint {
        let radius = diameter / 2
        guard playSize.width > diameter, playSize.height > diameter else {
            return CGPoint(x: playSize.width / 2, y: playSize.height / 2)
        }
        return CGPoint(
            x: min(max(point.x, radius), playSize.width - radius),
            y: min(max(point.y, radius), playSize.height - radius)
        )
    }

    // MARK: - Countdown

    private func startTimer() {
        resetCountdown()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func resetCountdown() {
        deadline = Date().addingTimeInterval(selectedInterval.rawValue)
        timeRemaining = selectedInterval.rawValue
    }

    private func tick() {
        guard phase == .playing else { return }
        let remaining = deadline.timeIntervalSinceNow
        if remaining <= 0 {
            timeRemaining = 0
            fail()
        } else {
            timeRemaining = remaining
        }
    }

    private func fail() {
        stopTimer()
        bestScore = max(bestScore, score)
        phase = .gameOver
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
