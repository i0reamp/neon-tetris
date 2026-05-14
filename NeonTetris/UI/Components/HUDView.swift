import SwiftUI

struct HUDView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 12) {
            scorePanel
            HStack(alignment: .top, spacing: 12) {
                holdPanel
                Spacer(minLength: 0)
                nextPanel
            }
        }
        .padding(.horizontal, 16)
    }

    private var scorePanel: some View {
        GlassPanel(cornerRadius: 18, tint: Color(hex: 0x6FE7FF)) {
            HStack(spacing: 18) {
                StatBlock(label: "SCORE", value: "\(engine.score.score)", accent: Color(hex: 0xC04CFF))
                Divider().background(Color.white.opacity(0.15))
                StatBlock(label: "LINES", value: "\(engine.score.lines)", accent: Color(hex: 0x39FF7A))
                Divider().background(Color.white.opacity(0.15))
                StatBlock(label: "LEVEL", value: "\(engine.score.level)", accent: Color(hex: 0xFFE100))
            }
        }
    }

    private var holdPanel: some View {
        GlassPanel(cornerRadius: 16, tint: Color(hex: 0xC04CFF)) {
            VStack(spacing: 8) {
                Text("HOLD")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.65))
                Group {
                    if let shape = engine.hold {
                        MiniPieceView(shape: shape, cellSize: 12)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
                .frame(width: 60, height: 36)
            }
        }
        .frame(width: 96)
    }

    private var nextPanel: some View {
        GlassPanel(cornerRadius: 16, tint: Color(hex: 0x39E6FF)) {
            VStack(alignment: .center, spacing: 8) {
                Text("NEXT")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.65))
                VStack(spacing: 8) {
                    ForEach(Array(engine.nextQueue.prefix(5).enumerated()), id: \.offset) { idx, shape in
                        MiniPieceView(shape: shape, cellSize: idx == 0 ? 13 : 10, dim: idx == 0 ? 1.0 : 0.7)
                            .frame(height: idx == 0 ? 36 : 26)
                    }
                }
            }
        }
        .frame(width: 96)
    }
}

private struct StatBlock: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: accent.opacity(0.7), radius: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
