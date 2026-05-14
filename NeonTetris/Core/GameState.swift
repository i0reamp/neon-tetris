import Foundation

enum GameState: Equatable {
    case ready
    case playing
    case paused
    case gameOver
    case clearingLines     // brief animation phase, input is locked
}

enum LineClearKind: Equatable {
    case none
    case single
    case double
    case triple
    case tetris

    init(_ count: Int) {
        switch count {
        case 1: self = .single
        case 2: self = .double
        case 3: self = .triple
        case 4: self = .tetris
        default: self = .none
        }
    }

    var displayName: String {
        switch self {
        case .none: return ""
        case .single: return "SINGLE"
        case .double: return "DOUBLE"
        case .triple: return "TRIPLE"
        case .tetris: return "TETRIS!"
        }
    }
}

/// Fired by GameEngine for renderer / audio / haptics consumers.
enum GameEvent: Equatable {
    case moved
    case rotated(success: Bool)
    case softDrop
    case hardDrop(rows: Int)
    case holdSwap
    case spawned(TetrominoShape)
    case locked(at: [GridPoint])
    case linesClearing(rows: [Int])
    case linesCleared(count: Int, kind: LineClearKind)
    case levelUp(Int)
    case gameOver
    case scoreAwarded(Int)
}
