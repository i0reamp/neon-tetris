import SwiftUI

/// Bridges raw gesture events from the SwiftUI layer to the engine + haptics.
/// Owns DAS-like state (continuous-drag horizontal repeat).
@MainActor
final class InputController: ObservableObject {
    private let engine: GameEngine
    private let haptics: HapticsManager
    private let settings: SettingsStore

    // Pan state
    private var panAccumulatedDx: CGFloat = 0
    private var panAccumulatedDy: CGFloat = 0
    private var panLastTranslation: CGSize = .zero
    private var fastDropArmed = false
    private var softDropTickAccum: CGFloat = 0

    /// Pixels per logical cell — set from the GameView once the scene knows.
    var cellSize: CGFloat = 32

    init(engine: GameEngine, haptics: HapticsManager = .shared, settings: SettingsStore) {
        self.engine = engine
        self.haptics = haptics
        self.settings = settings
    }

    // MARK: - Single actions

    func tapToRotate() {
        engine.rotateCW()
        haptics.rotate()
    }

    func twoFingerTapRotateCCW() {
        engine.rotateCCW()
        haptics.rotate()
    }

    func hardDropAction() {
        engine.hardDrop()
        haptics.hardDrop()
    }

    func holdAction() {
        engine.holdSwap()
        haptics.hold()
    }

    // MARK: - Pan

    func panChanged(translation: CGSize) {
        let dx = translation.width - panLastTranslation.width
        let dy = translation.height - panLastTranslation.height
        panLastTranslation = translation
        panAccumulatedDx += dx
        panAccumulatedDy += dy

        // Horizontal cell-snap movement
        while abs(panAccumulatedDx) >= cellSize * 0.55 {
            if panAccumulatedDx > 0 {
                engine.moveRight()
                panAccumulatedDx -= cellSize
            } else {
                engine.moveLeft()
                panAccumulatedDx += cellSize
            }
            haptics.move()
        }

        // Vertical: positive dy = swipe down = soft drop
        if panAccumulatedDy > cellSize * 0.5 {
            softDropTickAccum += panAccumulatedDy
            panAccumulatedDy = 0
            while softDropTickAccum >= cellSize * 0.5 {
                engine.softDropOnce()
                softDropTickAccum -= cellSize * 0.5
            }
        }

        // Strong upward fling = hard drop
        if panAccumulatedDy < -cellSize * 3.5, !fastDropArmed {
            fastDropArmed = true
            hardDropAction()
        }
    }

    func panEnded(translation: CGSize, velocity: CGSize) {
        // Final fling check
        if !fastDropArmed,
           velocity.height < -1600, abs(velocity.width) < 600 {
            hardDropAction()
        }
        resetPan()
    }

    func panCancelled() {
        resetPan()
    }

    private func resetPan() {
        panAccumulatedDx = 0
        panAccumulatedDy = 0
        panLastTranslation = .zero
        softDropTickAccum = 0
        fastDropArmed = false
    }
}
