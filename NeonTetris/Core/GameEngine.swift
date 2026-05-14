import Foundation
import Combine

@MainActor
final class GameEngine: ObservableObject {
    // MARK: - Published state
    @Published private(set) var board = Board()
    @Published private(set) var active: Tetromino?
    @Published private(set) var hold: TetrominoShape?
    @Published private(set) var nextQueue: [TetrominoShape] = []
    @Published private(set) var score = ScoreModel()
    @Published private(set) var state: GameState = .ready
    @Published private(set) var clearingRows: [Int] = []
    @Published private(set) var lastEvent: GameEvent?

    // MARK: - Internals
    private var bag = Bag7()
    private var gravityAccumulator: TimeInterval = 0
    private var lockDelay: TimeInterval = 0
    private let lockDelayMax: TimeInterval = 0.5
    private var hasUsedHold = false
    private let queuePreview = 5

    init() {
        refillQueue()
    }

    // MARK: - Lifecycle

    func start() {
        board = Board()
        score = ScoreModel()
        hold = nil
        hasUsedHold = false
        bag = Bag7()
        nextQueue = []
        refillQueue()
        spawnNext()
        state = .playing
    }

    func pause() {
        guard state == .playing else { return }
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = .playing
    }

    func reset() {
        state = .ready
        start()
    }

    // MARK: - Tick

    /// Called every frame by the game loop with the time delta in seconds.
    func tick(deltaTime: TimeInterval) {
        guard state == .playing, let _ = active else { return }
        gravityAccumulator += deltaTime
        let interval = score.gravityInterval
        while gravityAccumulator >= interval {
            gravityAccumulator -= interval
            attemptGravityStep()
        }

        // Accumulate lock delay only when the piece is resting on something.
        if let piece = active {
            var next = piece
            next.origin.y += 1
            if !board.canPlace(next) {
                lockDelay += deltaTime
                if lockDelay >= lockDelayMax {
                    lockPiece()
                }
            }
        }
    }

    private func attemptGravityStep() {
        guard let piece = active else { return }
        var next = piece
        next.origin.y += 1
        if board.canPlace(next) {
            active = next
        }
    }

    // MARK: - Input

    func moveLeft() { _ = move(dx: -1) }
    func moveRight() { _ = move(dx: 1) }

    func rotateCW() { _ = rotate(direction: 1) }
    func rotateCCW() { _ = rotate(direction: -1) }

    func softDropOnce() {
        guard state == .playing, let piece = active else { return }
        var next = piece
        next.origin.y += 1
        if board.canPlace(next) {
            active = next
            score.addSoftDrop(rows: 1)
            lockDelay = 0
            emit(.softDrop)
        } else {
            // already at the bottom — lock immediately
            lockPiece()
        }
    }

    func hardDrop() {
        guard state == .playing, let piece = active else { return }
        let distance = board.dropDistance(for: piece)
        var dropped = piece
        dropped.origin.y += distance
        active = dropped
        score.addHardDrop(rows: distance)
        emit(.hardDrop(rows: distance))
        lockPiece()
    }

    func holdSwap() {
        guard state == .playing, !hasUsedHold, let current = active else { return }
        hasUsedHold = true
        if let held = hold {
            hold = current.shape
            active = Tetromino.spawn(held, boardWidth: Board.width)
        } else {
            hold = current.shape
            active = nil
            spawnNext()
        }
        gravityAccumulator = 0
        lockDelay = 0
        emit(.holdSwap)
    }

    // MARK: - Private helpers

    private func refillQueue() {
        while nextQueue.count < queuePreview {
            nextQueue.append(bag.next())
        }
    }

    private func spawnNext() {
        guard let next = nextQueue.first else { return }
        nextQueue.removeFirst()
        refillQueue()
        let piece = Tetromino.spawn(next, boardWidth: Board.width)
        guard board.canPlace(piece) else {
            // top-out
            state = .gameOver
            emit(.gameOver)
            HighScoreStore.shared.record(
                score: score.score, lines: score.lines, level: score.level
            )
            return
        }
        active = piece
        hasUsedHold = false
        gravityAccumulator = 0
        lockDelay = 0
        emit(.spawned(next))
    }

    @discardableResult
    private func move(dx: Int) -> Bool {
        guard state == .playing, let piece = active else { return false }
        var next = piece
        next.origin.x += dx
        if board.canPlace(next) {
            active = next
            lockDelay = 0
            emit(.moved)
            return true
        }
        return false
    }

    @discardableResult
    private func rotate(direction: Int) -> Bool {
        guard state == .playing, let piece = active else { return false }
        let fromRot = piece.rotation & 3
        let toRot = (piece.rotation + direction) & 3
        let kicks = WallKick.kicks(shape: piece.shape, from: fromRot, to: toRot)
        for kick in kicks {
            var candidate = piece
            candidate.rotation = toRot
            candidate.origin.x += kick.x
            // SRS kicks use math y-up; our y is down, so invert the y component.
            candidate.origin.y -= kick.y
            if board.canPlace(candidate) {
                active = candidate
                lockDelay = 0
                emit(.rotated(success: true))
                return true
            }
        }
        emit(.rotated(success: false))
        return false
    }

    private func lockPiece() {
        guard let piece = active else { return }
        board.place(piece)
        emit(.locked(at: piece.cells()))

        let prevLevel = score.level
        let full = board.fullRows()
        if !full.isEmpty {
            clearingRows = full
            state = .clearingLines
            emit(.linesClearing(rows: full))
            // perform the clear after a short delay so renderer can play an animation
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 220_000_000)
                self?.finalizeClear(full: full, prevLevel: prevLevel)
            }
        } else {
            let bonus = score.registerLock(linesCleared: 0)
            if bonus > 0 { emit(.scoreAwarded(bonus)) }
            active = nil
            spawnNext()
        }
    }

    @MainActor
    private func finalizeClear(full: [Int], prevLevel: Int) {
        board.clear(rows: full)
        let bonus = score.registerLock(linesCleared: full.count)
        if bonus > 0 { emit(.scoreAwarded(bonus)) }
        emit(.linesCleared(count: full.count, kind: LineClearKind(full.count)))
        if score.level > prevLevel {
            emit(.levelUp(score.level))
        }
        clearingRows = []
        active = nil
        state = .playing
        spawnNext()
    }

    private func emit(_ event: GameEvent) {
        lastEvent = event
    }
}
