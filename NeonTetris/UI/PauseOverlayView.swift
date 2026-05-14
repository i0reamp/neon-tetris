import SwiftUI

struct PauseOverlayView: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.55))
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("PAUSED")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .tracking(8)
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: 0x6FE7FF).opacity(0.85), radius: 16)

                VStack(spacing: 14) {
                    NeonButton(title: "RESUME", systemImage: "play.fill",
                               accent: Color(hex: 0x39FF7A), prominent: true, action: onResume)
                    NeonButton(title: "RESTART", systemImage: "arrow.counterclockwise",
                               accent: Color(hex: 0xFFE100), action: onRestart)
                    NeonButton(title: "MAIN MENU", systemImage: "house.fill",
                               accent: Color(hex: 0xC04CFF), action: onMenu)
                }
                .frame(maxWidth: 340)
                .padding(.horizontal, 32)
            }
        }
    }
}
