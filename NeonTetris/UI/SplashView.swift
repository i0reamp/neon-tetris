import SwiftUI

struct SplashView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            AnimatedBackground()

            VStack(spacing: 12) {
                Spacer()
                NeonTitle(text: "NEON", accent: Color(hex: 0xC04CFF))
                    .opacity(titleVisible ? 1 : 0)
                    .scaleEffect(titleVisible ? 1 : 0.85)
                NeonTitle(text: "TETRIS", accent: Color(hex: 0x39E6FF))
                    .opacity(titleVisible ? 1 : 0)
                    .scaleEffect(titleVisible ? 1 : 0.85)
                Spacer()
                Text("LOADING")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(8)
                    .foregroundStyle(.white.opacity(subtitleVisible ? 0.65 : 0.0))
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.05)) {
                titleVisible = true
            }
            withAnimation(.easeInOut(duration: 0.6).delay(0.4)) {
                subtitleVisible = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }

            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    SoundEngine.shared.play(.menuOpen)
                    coordinator.go(to: .mainMenu)
                }
            }
        }
    }
}

struct NeonTitle: View {
    let text: String
    let accent: Color

    var body: some View {
        Text(text)
            .font(.system(size: 72, weight: .black, design: .rounded))
            .tracking(8)
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, accent],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: accent.opacity(0.95), radius: 18, x: 0, y: 0)
            .shadow(color: accent.opacity(0.55), radius: 38, x: 0, y: 0)
    }
}
