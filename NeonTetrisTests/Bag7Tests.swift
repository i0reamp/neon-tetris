import XCTest
@testable import NeonTetris

final class Bag7Tests: XCTestCase {
    func testEverySevenContainsAllShapes() {
        var bag = Bag7()
        for _ in 0..<10 {
            var seen = Set<TetrominoShape>()
            for _ in 0..<7 { seen.insert(bag.next()) }
            XCTAssertEqual(seen.count, 7, "Each bag of 7 must contain all 7 unique shapes.")
        }
    }

    func testPeekDoesNotConsume() {
        var bag = Bag7()
        let peeked = bag.peek(5)
        let popped = (0..<5).map { _ in bag.next() }
        XCTAssertEqual(peeked, popped)
    }
}
