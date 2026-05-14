import SwiftUI

/// Small preview of a tetromino used in HOLD / NEXT panels.
struct MiniPieceView: View {
    let shape: TetrominoShape
    var cellSize: CGFloat = 14
    var dim: Double = 1.0

    var body: some View {
        let cells = ShapeData.offsets(for: shape, rotation: 0)
        let minX = cells.map { $0.x }.min() ?? 0
        let maxX = cells.map { $0.x }.max() ?? 0
        let minY = cells.map { $0.y }.min() ?? 0
        let maxY = cells.map { $0.y }.max() ?? 0
        let w = CGFloat(maxX - minX + 1) * cellSize
        let h = CGFloat(maxY - minY + 1) * cellSize
        return ZStack {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, p in
                miniBlock
                    .frame(width: cellSize, height: cellSize)
                    .offset(x: CGFloat(p.x - minX) * cellSize, y: CGFloat(p.y - minY) * cellSize)
            }
        }
        .frame(width: w, height: h, alignment: .topLeading)
    }

    @ViewBuilder private var miniBlock: some View {
        let color = shape.color
        RoundedRectangle(cornerRadius: cellSize * 0.18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        color.coreColor.opacity(0.85 * dim),
                        color.coreColor.opacity(0.35 * dim)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cellSize * 0.18, style: .continuous)
                    .stroke(color.glowColor.opacity(0.9 * dim), lineWidth: 1.0)
            )
            .shadow(color: color.glowColor.opacity(0.55 * dim), radius: 6)
    }
}
