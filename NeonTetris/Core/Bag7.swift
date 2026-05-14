import Foundation

/// Classic 7-bag randomizer. Shuffles all 7 tetrominoes, yields one at a time,
/// then refills.
struct Bag7 {
    private var queue: [TetrominoShape] = []
    private var rng: SystemRandomNumberGenerator

    init(seed: UInt64? = nil) {
        self.rng = SystemRandomNumberGenerator()
        // We always keep two bags worth queued so callers can preview far ahead.
        refill()
        refill()
    }

    /// Peek the next `count` shapes without consuming.
    func peek(_ count: Int) -> [TetrominoShape] {
        Array(queue.prefix(count))
    }

    /// Pop the next shape.
    mutating func next() -> TetrominoShape {
        if queue.count < TetrominoShape.allCases.count {
            refill()
        }
        return queue.removeFirst()
    }

    private mutating func refill() {
        var bag = TetrominoShape.allCases
        bag.shuffle(using: &rng)
        queue.append(contentsOf: bag)
    }
}
