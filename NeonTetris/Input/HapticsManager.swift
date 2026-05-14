import Foundation
import CoreHaptics
import UIKit

/// Wraps CoreHaptics with graceful UIFeedbackGenerator fallbacks.
@MainActor
final class HapticsManager {
    static let shared = HapticsManager()

    var isEnabled: Bool = true

    private var engine: CHHapticEngine?
    private let supportsHaptics: Bool

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let success = UINotificationFeedbackGenerator()

    private init() {
        let caps = CHHapticEngine.capabilitiesForHardware()
        supportsHaptics = caps.supportsHaptics
        prepareGenerators()
        startEngine()
    }

    private func prepareGenerators() {
        light.prepare(); medium.prepare(); rigid.prepare(); soft.prepare(); success.prepare()
    }

    private func startEngine() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            engine?.stoppedHandler = { _ in }
        } catch {
            engine = nil
        }
    }

    // MARK: - Public

    func move() { tap(style: .light) }
    func rotate() { tap(style: .soft) }
    func softDrop() { tap(style: .light) }
    func hold() { tap(style: .medium) }
    func hardDrop() { play(intensity: 0.9, sharpness: 0.85, duration: 0.05) }
    func lineClear(count: Int) {
        // multi-pop for combos
        let times = max(1, min(4, count))
        for i in 0..<times {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.045) { [weak self] in
                self?.play(intensity: 0.85, sharpness: 0.7, duration: 0.04)
            }
        }
    }
    func tetris() {
        play(intensity: 1.0, sharpness: 0.5, duration: 0.18)
    }
    func gameOver() {
        play(intensity: 1.0, sharpness: 0.2, duration: 0.45)
    }
    func levelUp() {
        play(intensity: 0.7, sharpness: 0.9, duration: 0.10)
    }

    // MARK: - Internals

    private func tap(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        switch style {
        case .light: light.impactOccurred()
        case .medium: medium.impactOccurred()
        case .rigid: rigid.impactOccurred()
        case .soft: soft.impactOccurred()
        @unknown default: light.impactOccurred()
        }
    }

    private func play(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard isEnabled else { return }
        guard supportsHaptics, let engine else {
            medium.impactOccurred()
            return
        }
        let i = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let s = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [i, s],
            relativeTime: 0,
            duration: duration
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            medium.impactOccurred()
        }
    }
}
