import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            AnimatedBackground()

            VStack(spacing: 28) {
                Spacer(minLength: 60)

                VStack(spacing: -2) {
                    NeonTitle(text: "NEON", accent: Color(hex: 0xC04CFF))
                    NeonTitle(text: "TETRIS", accent: Color(hex: 0x39E6FF))
                }

                bestScoreCard

                Spacer()

                VStack(spacing: 14) {
                    NeonButton(title: "PLAY", systemImage: "play.fill",
                               accent: Color(hex: 0x39E6FF), prominent: true) {
                        coordinator.go(to: .game)
                    }
                    NeonButton(title: "SETTINGS", systemImage: "slider.horizontal.3",
                               accent: Color(hex: 0xC04CFF)) {
                        coordinator.go(to: .settings)
                    }
                    NeonButton(title: "ABOUT", systemImage: "info.circle",
                               accent: Color(hex: 0xFFA12B)) {
                        coordinator.go(to: .about)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }

    private var bestScoreCard: some View {
        GlassPanel(cornerRadius: 18, tint: Color(hex: 0xFFE100)) {
            VStack(spacing: 6) {
                Text("PERSONAL BEST")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(HighScoreStore.shared.highScore)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: 0xFFE100).opacity(0.8), radius: 12)
                HStack(spacing: 24) {
                    Stat(label: "LINES", value: "\(HighScoreStore.shared.highLines)")
                    Stat(label: "LEVEL", value: "\(HighScoreStore.shared.highLevel)")
                }
            }
        }
        .padding(.horizontal, 40)
    }

    private struct Stat: View {
        let label: String
        let value: String
        var body: some View {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}
