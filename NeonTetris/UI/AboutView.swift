import SwiftUI

struct AboutView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (build \(b))"
    }

    var body: some View {
        ZStack {
            AnimatedBackground()
            VStack(spacing: 20) {
                Text("ABOUT")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: 0xFFA12B), radius: 12)
                    .padding(.top, 40)

                ScrollView {
                    VStack(spacing: 14) {
                        GlassPanel(cornerRadius: 18, tint: Color(hex: 0x6FE7FF)) {
                            VStack(alignment: .leading, spacing: 8) {
                                row("Project", "NeonTetris")
                                row("Version", version)
                                row("Build target", "iPhone, iOS 17+")
                                row("Engine", "SwiftUI + SpriteKit")
                                row("Audio", "Procedural (AVAudioEngine)")
                                row("Haptics", "CoreHaptics + UIKit fallback")
                            }
                        }

                        GlassPanel(cornerRadius: 18, tint: Color(hex: 0xC04CFF)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CONTROLS")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .tracking(3)
                                    .foregroundStyle(.white.opacity(0.7))
                                row("Swipe left/right", "Move piece")
                                row("Swipe down", "Soft drop")
                                row("Strong swipe up", "Hard drop")
                                row("Tap playfield", "Rotate CW")
                                row("HOLD button", "Swap held piece")
                                row("Pause button", "Pause / Resume")
                            }
                        }

                        GlassPanel(cornerRadius: 18, tint: Color(hex: 0x39FF7A)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("RULES")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .tracking(3)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text("Classic guideline Tetris. 7-bag randomizer, SRS wall kicks, classic scoring (100/300/500/800 × level), level up every 10 lines, top-out ends the game.")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }

                NeonButton(title: "BACK", systemImage: "chevron.left", accent: Color(hex: 0x6FE7FF)) {
                    coordinator.go(to: .mainMenu)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 30)
            }
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
