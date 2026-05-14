import SwiftUI

struct NeonButton: View {
    let title: String
    var systemImage: String? = nil
    var accent: Color = Color(hex: 0x6FE7FF)
    var prominent: Bool = false
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            HapticsManager.shared.move()
            SoundEngine.shared.play(.menuConfirm)
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: prominent ? 22 : 18, weight: prominent ? .heavy : .semibold, design: .rounded))
                    .tracking(2)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, prominent ? 18 : 14)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(prominent ? 0.45 : 0.22),
                                        accent.opacity(prominent ? 0.18 : 0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [accent.opacity(0.95), accent.opacity(0.25)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.4
                            )
                    }
                    .shadow(color: accent.opacity(0.5), radius: prominent ? 16 : 10, x: 0, y: 0)
            }
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded { _ in pressed = false })
    }
}
