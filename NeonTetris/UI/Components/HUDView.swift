import SwiftUI

struct HUDView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 8) {
            scorePanel
            HStack(spacing: 10) {
                holdPanel
                nextPanel
            }
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Score row

    private var scorePanel: some View {
        GlassPanel(cornerRadius: 16, tint: Color(hex: 0x6FE7FF)) {
            HStack(spacing: 12) {
                StatBlock(label: "SCORE", value: "\(engine.score.score)", accent: Color(hex: 0xC04CFF))
                Divider().background(Color.white.opacity(0.15))
                StatBlock(label: "LINES", value: "\(engine.score.lines)", accent: Color(hex: 0x39FF7A))
                Divider().background(Color.white.opacity(0.15))
                StatBlock(label: "LEVEL", value: "\(engine.score.level)", accent: Color(hex: 0xFFE100))
            }
        }
    }

    // MARK: - Hold + Next (one short row)

    private var holdPanel: some View {
        GlassPanel(cornerRadius: 14, tint: Color(hex: 0xC04CFF)) {
            HStack(spacing: 10) {
                Text("HOLD")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.65))
                ZStack {
                    Color.clear.frame(width: 44, height: 30)
                    if let shape = engine.hold {
                        MiniPieceView(shape: shape, cellSize: 8)
                    }
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var nextPanel: some View {
        GlassPanel(cornerRadius: 14, tint: Color(hex: 0x39E6FF)) {
            HStack(spacing: 10) {
                Text("NEXT")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.65))
                HStack(spacing: 8) {
                    ForEach(Array(engine.nextQueue.prefix(5).enumerated()), id: \.offset) { idx, shape in
                        ZStack {
                            Color.clear.frame(width: 32, height: 30)
                            MiniPieceView(
                                shape: shape,
                                cellSize: idx == 0 ? 8 : 7,
                                dim: idx == 0 ? 1.0 : 0.7
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatBlock: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: accent.opacity(0.7), radius: 6)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
