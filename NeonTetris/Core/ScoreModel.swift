import Foundation

/// Classic Tetris guideline scoring & level curve.
struct ScoreModel {
    private(set) var score: Int = 0
    private(set) var lines: Int = 0
    private(set) var level: Int = 1
    private(set) var combo: Int = -1   // -1 means no active combo
    private(set) var lastClearWasTetris = false

    /// Soft drop awards 1 point per row.
    mutating func addSoftDrop(rows: Int) {
        score += max(0, rows)
    }

    /// Hard drop awards 2 points per row.
    mutating func addHardDrop(rows: Int) {
        score += 2 * max(0, rows)
    }

    /// Called after a piece locks. Returns the awarded line-clear bonus
    /// (without drop points, which were added separately).
    @discardableResult
    mutating func registerLock(linesCleared: Int) -> Int {
        let basePoints: Int
        switch linesCleared {
        case 1: basePoints = 100
        case 2: basePoints = 300
        case 3: basePoints = 500
        case 4: basePoints = 800
        default: basePoints = 0
        }

        var awarded = basePoints * level

        if linesCleared > 0 {
            combo += 1
            if combo > 0 {
                awarded += 50 * combo * level
            }
            lines += linesCleared
            lastClearWasTetris = (linesCleared == 4)
            updateLevel()
        } else {
            combo = -1
            lastClearWasTetris = false
        }

        score += awarded
        return awarded
    }

    private mutating func updateLevel() {
        // Level up every 10 lines, capped to 20.
        let newLevel = min(20, 1 + lines / 10)
        level = max(level, newLevel)
    }

    /// Gravity interval in seconds, by level. Approx. NES/guideline curve.
    var gravityInterval: TimeInterval {
        let table: [TimeInterval] = [
            1.000, 0.793, 0.618, 0.473, 0.355,
            0.262, 0.190, 0.135, 0.094, 0.064,
            0.043, 0.028, 0.018, 0.012, 0.008,
            0.005, 0.004, 0.003, 0.002, 0.002,
            0.001
        ]
        return table[min(level, table.count - 1)]
    }
}
