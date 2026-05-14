import Foundation

/// Playfield. Coordinates: x in [0, width), y in [0, height).
/// y = 0 is the top, y = height-1 is the bottom (where the piece comes to rest).
/// We use `hiddenRows` at the top so pieces can spawn above the visible area.
struct Board {
    static let width = 10
    static let visibleHeight = 20
    static let hiddenRows = 2
    static let height = visibleHeight + hiddenRows

    private(set) var cells: [[Cell]]

    init() {
        cells = Array(
            repeating: Array(repeating: Cell.empty, count: Board.width),
            count: Board.height
        )
    }

    func cell(at p: GridPoint) -> Cell {
        guard inBounds(p) else { return .filled(.I) /* sentinel — out-of-bounds counts as blocked */ }
        return cells[p.y][p.x]
    }

    func inBounds(_ p: GridPoint) -> Bool {
        p.x >= 0 && p.x < Board.width && p.y >= 0 && p.y < Board.height
    }

    /// Returns true if the cell is empty AND in bounds (left/right/bottom).
    /// Out-of-bounds is treated as blocked.
    func isFree(_ p: GridPoint) -> Bool {
        guard p.x >= 0, p.x < Board.width, p.y < Board.height else { return false }
        if p.y < 0 { return true } // above the field — pieces may exist there during spawn/rotate
        return !cells[p.y][p.x].isFilled
    }

    /// Checks whether the piece fits on the board with no collisions.
    func canPlace(_ piece: Tetromino) -> Bool {
        for c in piece.cells() where !isFree(c) {
            return false
        }
        return true
    }

    /// Lock a piece onto the board.
    mutating func place(_ piece: Tetromino) {
        for c in piece.cells() {
            guard c.y >= 0, c.y < Board.height, c.x >= 0, c.x < Board.width else { continue }
            cells[c.y][c.x] = .filled(piece.shape)
        }
    }

    /// Returns the indices of full rows.
    func fullRows() -> [Int] {
        var rows: [Int] = []
        for y in 0..<Board.height {
            if cells[y].allSatisfy({ $0.isFilled }) {
                rows.append(y)
            }
        }
        return rows
    }

    /// Clear given row indices, dropping the rows above down. Returns the count cleared.
    @discardableResult
    mutating func clear(rows: [Int]) -> Int {
        guard !rows.isEmpty else { return 0 }
        let sorted = rows.sorted()
        for y in sorted {
            cells.remove(at: y)
            cells.insert(Array(repeating: .empty, count: Board.width), at: 0)
        }
        return sorted.count
    }

    /// Drops the piece as far down as it will go, returns the new piece.
    func ghost(for piece: Tetromino) -> Tetromino {
        var p = piece
        while true {
            var next = p
            next.origin.y += 1
            if canPlace(next) {
                p = next
            } else {
                break
            }
        }
        return p
    }

    /// Number of rows the piece would fall before locking.
    func dropDistance(for piece: Tetromino) -> Int {
        ghost(for: piece).origin.y - piece.origin.y
    }
}
