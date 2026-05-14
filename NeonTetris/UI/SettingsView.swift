import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            AnimatedBackground()
            VStack(spacing: 16) {
                header

                ScrollView {
                    VStack(spacing: 14) {
                        toggleRow(
                            title: "SOUND",
                            subtitle: "Procedural synth FX",
                            systemImage: "speaker.wave.2.fill",
                            tint: Color(hex: 0x39E6FF),
                            isOn: Binding(get: { settings.soundEnabled },
                                          set: { settings.soundEnabled = $0 })
                        )

                        toggleRow(
                            title: "HAPTICS",
                            subtitle: "Vibration on actions",
                            systemImage: "waveform",
                            tint: Color(hex: 0xC04CFF),
                            isOn: Binding(get: { settings.hapticsEnabled },
                                          set: { settings.hapticsEnabled = $0 })
                        )

                        intensityRow

                        resetRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }

                Spacer(minLength: 12)

                NeonButton(title: "BACK", systemImage: "chevron.left",
                           accent: Color(hex: 0x6FE7FF)) {
                    coordinator.go(to: .mainMenu)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 30)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("SETTINGS")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .tracking(6)
                .foregroundStyle(.white)
                .shadow(color: Color(hex: 0xC04CFF), radius: 12)
        }
        .padding(.top, 40)
    }

    private func toggleRow(title: String, subtitle: String, systemImage: String, tint: Color, isOn: Binding<Bool>) -> some View {
        GlassPanel(cornerRadius: 18, tint: tint) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(tint.opacity(0.25)).overlay(Circle().stroke(tint, lineWidth: 1)))
                    .shadow(color: tint.opacity(0.55), radius: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(tint)
            }
        }
    }

    private var intensityRow: some View {
        GlassPanel(cornerRadius: 18, tint: Color(hex: 0xFFE100)) {
            VStack(alignment: .leading, spacing: 10) {
                Label("VISUAL INTENSITY", systemImage: "sparkles")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    ForEach(VisualIntensity.allCases, id: \.self) { level in
                        Button {
                            settings.visualIntensity = level
                            SoundEngine.shared.play(.menuConfirm)
                            HapticsManager.shared.move()
                        } label: {
                            Text(level.displayName.uppercased())
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .tracking(2)
                                .foregroundStyle(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background {
                                    let selected = settings.visualIntensity == level
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(hex: 0xFFE100).opacity(selected ? 0.32 : 0.08))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: 0xFFE100).opacity(selected ? 1.0 : 0.4),
                                                        lineWidth: selected ? 1.4 : 0.8)
                                        )
                                        .shadow(color: Color(hex: 0xFFE100).opacity(selected ? 0.5 : 0), radius: 8)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var resetRow: some View {
        GlassPanel(cornerRadius: 18, tint: Color(hex: 0xFF3D6E)) {
            VStack(alignment: .leading, spacing: 10) {
                Label("PERSONAL BEST", systemImage: "trophy.fill")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white)
                Text("Score: \(HighScoreStore.shared.highScore), Lines: \(HighScoreStore.shared.highLines), Level: \(HighScoreStore.shared.highLevel)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                NeonButton(title: "RESET RECORDS", systemImage: "trash.fill",
                           accent: Color(hex: 0xFF3D6E)) {
                    HighScoreStore.shared.reset()
                }
            }
        }
    }
}
