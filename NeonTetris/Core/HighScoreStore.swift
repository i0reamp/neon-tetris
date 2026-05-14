import Foundation

/// Persists best score / lines / level in UserDefaults.
final class HighScoreStore {
    static let shared = HighScoreStore()
    private let defaults = UserDefaults.standard

    private enum Key {
        static let score = "NeonTetris.highScore"
        static let lines = "NeonTetris.highLines"
        static let level = "NeonTetris.highLevel"
    }

    var highScore: Int { defaults.integer(forKey: Key.score) }
    var highLines: Int { defaults.integer(forKey: Key.lines) }
    var highLevel: Int { max(1, defaults.integer(forKey: Key.level)) }

    /// Updates personal best. Returns true if any record was beaten.
    @discardableResult
    func record(score: Int, lines: Int, level: Int) -> Bool {
        var updated = false
        if score > highScore { defaults.set(score, forKey: Key.score); updated = true }
        if lines > highLines { defaults.set(lines, forKey: Key.lines); updated = true }
        if level > highLevel { defaults.set(level, forKey: Key.level); updated = true }
        return updated
    }

    func reset() {
        defaults.removeObject(forKey: Key.score)
        defaults.removeObject(forKey: Key.lines)
        defaults.removeObject(forKey: Key.level)
    }
}
