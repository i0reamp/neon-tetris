import Foundation
import SwiftUI

enum TetrominoShape: Int, CaseIterable, Codable {
    case I, O, T, S, Z, J, L

    var color: TetrominoColor {
        switch self {
        case .I: return .init(hexCore: 0x00F0FF, hexGlow: 0x60FFFF)
        case .O: return .init(hexCore: 0xFFE100, hexGlow: 0xFFF59A)
        case .T: return .init(hexCore: 0xC04CFF, hexGlow: 0xE39CFF)
        case .S: return .init(hexCore: 0x39FF7A, hexGlow: 0x9CFFB8)
        case .Z: return .init(hexCore: 0xFF3D6E, hexGlow: 0xFF9AB1)
        case .J: return .init(hexCore: 0x3A7BFF, hexGlow: 0x9CB8FF)
        case .L: return .init(hexCore: 0xFFA12B, hexGlow: 0xFFD79A)
        }
    }

    var symbol: String {
        switch self {
        case .I: return "I"
        case .O: return "O"
        case .T: return "T"
        case .S: return "S"
        case .Z: return "Z"
        case .J: return "J"
        case .L: return "L"
        }
    }
}

struct TetrominoColor: Equatable {
    let core: UInt32
    let glow: UInt32

    init(hexCore: UInt32, hexGlow: UInt32) {
        self.core = hexCore
        self.glow = hexGlow
    }

    var coreColor: Color { Color(hex: core) }
    var glowColor: Color { Color(hex: glow) }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

/// Cell occupant on the board.
enum Cell: Equatable {
    case empty
    case filled(TetrominoShape)

    var isFilled: Bool {
        if case .empty = self { return false } else { return true }
    }

    var shape: TetrominoShape? {
        if case .filled(let s) = self { return s } else { return nil }
    }
}

/// Rotation index 0..3 (SRS).
struct Tetromino: Equatable {
    let shape: TetrominoShape
    var rotation: Int          // 0..3
    var origin: GridPoint      // top-left of the bounding box

    /// Cells of this piece in grid coordinates.
    func cells() -> [GridPoint] {
        Self.cells(shape: shape, rotation: rotation, origin: origin)
    }

    static func cells(shape: TetrominoShape, rotation: Int, origin: GridPoint) -> [GridPoint] {
        let offsets = ShapeData.offsets(for: shape, rotation: rotation & 3)
        return offsets.map { GridPoint(x: origin.x + $0.x, y: origin.y + $0.y) }
    }

    /// Returns spawn piece for a new shape at the top of a `boardWidth`-wide board.
    static func spawn(_ shape: TetrominoShape, boardWidth: Int) -> Tetromino {
        let bbox: Int = shape == .I ? 4 : (shape == .O ? 2 : 3)
        let x = (boardWidth - bbox) / 2

        // Compute origin.y so that the topmost filled cell of the spawn
        // rotation lands exactly on the first visible row.
        let cells = ShapeData.offsets(for: shape, rotation: 0)
        let topLocalY = cells.map { $0.y }.min() ?? 0
        let y = Board.hiddenRows - topLocalY
        return Tetromino(shape: shape, rotation: 0, origin: GridPoint(x: x, y: y))
    }
}

struct GridPoint: Hashable {
    var x: Int
    var y: Int

    static let zero = GridPoint(x: 0, y: 0)
    static func + (lhs: GridPoint, rhs: GridPoint) -> GridPoint {
        GridPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

/// Shape data using local 4x4 grid offsets per rotation.
/// Coordinate system: x right, y down. Rotation 0 is the SRS spawn orientation.
enum ShapeData {
    static func offsets(for shape: TetrominoShape, rotation: Int) -> [GridPoint] {
        switch shape {
        case .I:
            switch rotation & 3 {
            case 0: return [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 3, y: 1)]
            case 1: return [GridPoint(x: 2, y: 0), GridPoint(x: 2, y: 1), GridPoint(x: 2, y: 2), GridPoint(x: 2, y: 3)]
            case 2: return [GridPoint(x: 0, y: 2), GridPoint(x: 1, y: 2), GridPoint(x: 2, y: 2), GridPoint(x: 3, y: 2)]
            default: return [GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2), GridPoint(x: 1, y: 3)]
            }
        case .O:
            // O does not rotate; we always return the same 2x2.
            return [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)]
        case .T:
            switch rotation & 3 {
            case 0: return [GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)]
            case 1: return [GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 1, y: 2)]
            case 2: return [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 1, y: 2)]
            default: return [GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2)]
            }
        case .S:
            switch rotation & 3 {
            case 0: return [GridPoint(x: 1, y: 0), GridPoint(x: 2, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)]
            case 1: return [GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 2, y: 2)]
            case 2: return [GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 0, y: 2), GridPoint(x: 1, y: 2)]
            default: return [GridPoint(x: 0, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2)]
            }
        case .Z:
            switch rotation & 3 {
            case 0: return [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)]
            case 1: return [GridPoint(x: 2, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 1, y: 2)]
            case 2: return [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2), GridPoint(x: 2, y: 2)]
            default: return [GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 0, y: 2)]
            }
        case .J:
            switch rotation & 3 {
            case 0: return [GridPoint(x: 0, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)]
            case 1: return [GridPoint(x: 1, y: 0), GridPoint(x: 2, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2)]
            case 2: return [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 2, y: 2)]
            default: return [GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 0, y: 2), GridPoint(x: 1, y: 2)]
            }
        case .L:
            switch rotation & 3 {
            case 0: return [GridPoint(x: 2, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)]
            case 1: return [GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2), GridPoint(x: 2, y: 2)]
            case 2: return [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 0, y: 2)]
            default: return [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2)]
            }
        }
    }
}

/// SRS kick tables. For most pieces we use the JLSTZ table; I has its own.
enum WallKick {
    /// Returns kick offsets (dx, dy) to try for a CW rotation `from -> to` of `shape`.
    static func kicks(shape: TetrominoShape, from: Int, to: Int) -> [GridPoint] {
        let f = from & 3, t = to & 3
        if shape == .O { return [GridPoint.zero] }
        let table: [[GridPoint]] = shape == .I ? iTable : jlstzTable
        // Index by transition pair.
        let idx: Int
        switch (f, t) {
        case (0, 1): idx = 0
        case (1, 0): idx = 1
        case (1, 2): idx = 2
        case (2, 1): idx = 3
        case (2, 3): idx = 4
        case (3, 2): idx = 5
        case (3, 0): idx = 6
        case (0, 3): idx = 7
        default: idx = 0
        }
        return table[idx]
    }

    private static let jlstzTable: [[GridPoint]] = [
        // 0->1
        [GridPoint(x: 0, y: 0), GridPoint(x: -1, y: 0), GridPoint(x: -1, y: -1), GridPoint(x: 0, y: 2), GridPoint(x: -1, y: 2)],
        // 1->0
        [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 0, y: -2), GridPoint(x: 1, y: -2)],
        // 1->2
        [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 0, y: -2), GridPoint(x: 1, y: -2)],
        // 2->1
        [GridPoint(x: 0, y: 0), GridPoint(x: -1, y: 0), GridPoint(x: -1, y: -1), GridPoint(x: 0, y: 2), GridPoint(x: -1, y: 2)],
        // 2->3
        [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 1, y: -1), GridPoint(x: 0, y: 2), GridPoint(x: 1, y: 2)],
        // 3->2
        [GridPoint(x: 0, y: 0), GridPoint(x: -1, y: 0), GridPoint(x: -1, y: 1), GridPoint(x: 0, y: -2), GridPoint(x: -1, y: -2)],
        // 3->0
        [GridPoint(x: 0, y: 0), GridPoint(x: -1, y: 0), GridPoint(x: -1, y: 1), GridPoint(x: 0, y: -2), GridPoint(x: -1, y: -2)],
        // 0->3
        [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 1, y: -1), GridPoint(x: 0, y: 2), GridPoint(x: 1, y: 2)]
    ]

    private static let iTable: [[GridPoint]] = [
        // 0->1
        [GridPoint(x: 0, y: 0), GridPoint(x: -2, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: -2, y: 1), GridPoint(x: 1, y: -2)],
        // 1->0
        [GridPoint(x: 0, y: 0), GridPoint(x: 2, y: 0), GridPoint(x: -1, y: 0), GridPoint(x: 2, y: -1), GridPoint(x: -1, y: 2)],
        // 1->2
        [GridPoint(x: 0, y: 0), GridPoint(x: -1, y: 0), GridPoint(x: 2, y: 0), GridPoint(x: -1, y: -2), GridPoint(x: 2, y: 1)],
        // 2->1
        [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: -2, y: 0), GridPoint(x: 1, y: 2), GridPoint(x: -2, y: -1)],
        // 2->3
        [GridPoint(x: 0, y: 0), GridPoint(x: 2, y: 0), GridPoint(x: -1, y: 0), GridPoint(x: 2, y: -1), GridPoint(x: -1, y: 2)],
        // 3->2
        [GridPoint(x: 0, y: 0), GridPoint(x: -2, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: -2, y: 1), GridPoint(x: 1, y: -2)],
        // 3->0
        [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: -2, y: 0), GridPoint(x: 1, y: 2), GridPoint(x: -2, y: -1)],
        // 0->3
        [GridPoint(x: 0, y: 0), GridPoint(x: -1, y: 0), GridPoint(x: 2, y: 0), GridPoint(x: -1, y: -2), GridPoint(x: 2, y: 1)]
    ]
}
