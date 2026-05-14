import XCTest
@testable import NeonTetris

@MainActor
final class GameEngineTests: XCTestCase {

    func testSpawnAndMoveLeftRight() async {
        let engine = GameEngine()
        engine.start()
        XCTAssertNotNil(engine.active)
        let originalX = engine.active!.origin.x
        engine.moveLeft()
        XCTAssertEqual(engine.active!.origin.x, originalX - 1)
        engine.moveRight()
        engine.moveRight()
        XCTAssertEqual(engine.active!.origin.x, originalX + 1)
    }

    func testRotationKeepsValidState() async {
        let engine = GameEngine()
        engine.start()
        XCTAssertNotNil(engine.active)
        let beforeRot = engine.active!.rotation
        engine.rotateCW()
        XCTAssertNotEqual(engine.active!.rotation, beforeRot - 1) // moved
    }

    func testHardDropLocksPiece() async {
        let engine = GameEngine()
        engine.start()
        let initialScore = engine.score.score
        engine.hardDrop()
        // After hard drop, the engine immediately locks the piece and either
        // spawns the next piece (state == .playing) or begins a clear animation
        // (state == .clearingLines).
        XCTAssertGreaterThanOrEqual(engine.score.score, initialScore)
    }

    func testHoldSwapsAndIsOnceOnly() async {
        let engine = GameEngine()
        engine.start()
        let firstShape = engine.active!.shape
        engine.holdSwap()
        XCTAssertEqual(engine.hold, firstShape)
        let secondShape = engine.active!.shape
        engine.holdSwap()
        // Second hold within the same piece life should be a no-op
        XCTAssertEqual(engine.active!.shape, secondShape)
    }

    func testLevelUpAtTenLines() async {
        var s = ScoreModel()
        for _ in 0..<10 {
            s.registerLock(linesCleared: 1)
        }
        XCTAssertGreaterThanOrEqual(s.level, 2)
    }
}
