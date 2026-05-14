import SwiftUI

struct GameOverView: View {
    @ObservedObject var engine: GameEngine
    let onRestart: () -> Void
    let onMenu: () -> Void

    @State private var newRecord = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.55))
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("GAME OVER")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .tracking(8)
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: 0xFF3D6E), radius: 16)

                if newRecord {
                    Text("NEW RECORD!")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(6)
                        .foregroundStyle(Color(hex: 0xFFE100))
                        .shadow(color: Color(hex: 0xFFE100).opacity(0.8), radius: 12)
                }

                GlassPanel(cornerRadius: 22, tint: Color(hex: 0xFFE100)) {
                    HStack(spacing: 28) {
                        StatColumn(label: "SCORE", value: "\(engine.score.score)", accent: Color(hex: 0xC04CFF))
                        StatColumn(label: "LINES", value: "\(engine.score.lines)", accent: Color(hex: 0x39FF7A))
                        StatColumn(label: "LEVEL", value: "\(engine.score.level)", accent: Color(hex: 0x39E6FF))
                    }
                }
                .frame(maxWidth: 360)

                VStack(spacing: 12) {
                    NeonButton(title: "PLAY AGAIN", systemImage: "play.fill",
                               accent: Color(hex: 0x39FF7A), prominent: true, action: onRestart)
                    NeonButton(title: "MAIN MENU", systemImage: "house.fill",
                               accent: Color(hex: 0xC04CFF), action: onMenu)
                }
                .frame(maxWidth: 340)
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            let store = HighScoreStore.shared
            newRecord = engine.score.score >= store.highScore && engine.score.score > 0
        }
    }
}

private struct StatColumn: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: accent.opacity(0.8), radius: 8)
        }
        .frame(maxWidth: .infinity)
    }
}
