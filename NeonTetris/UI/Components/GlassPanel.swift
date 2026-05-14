import SwiftUI

struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = 22
    var tint: Color = Color(hex: 0x6FE7FF)
    var strokeOpacity: Double = 0.35
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.10),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [tint.opacity(strokeOpacity), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    }
                    .shadow(color: tint.opacity(0.25), radius: 20, x: 0, y: 0)
            }
    }
}
