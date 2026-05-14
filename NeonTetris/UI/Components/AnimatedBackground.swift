import SwiftUI

/// SwiftUI-only animated gradient background used on menu screens.
struct AnimatedBackground: View {
    @State private var anim = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x07061A),
                    Color(hex: 0x140832),
                    Color(hex: 0x05121F)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                Canvas { gctx, size in
                    drawNebula(in: gctx, size: size, time: t)
                }
                .blur(radius: 30)
                .blendMode(.plusLighter)
                .ignoresSafeArea()
                .opacity(0.85)
            }

            // Subtle vignette
            RadialGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.55)],
                center: .center,
                startRadius: 200,
                endRadius: 700
            )
            .ignoresSafeArea()
        }
    }

    private func drawNebula(in ctx: GraphicsContext, size: CGSize, time: TimeInterval) {
        let blobs: [(CGPoint, Color, CGFloat)] = [
            (CGPoint(x: size.width * (0.30 + 0.06 * CGFloat(sin(time * 0.21))),
                     y: size.height * (0.25 + 0.05 * CGFloat(cos(time * 0.17)))),
             Color(hex: 0xC04CFF), size.width * 0.55),
            (CGPoint(x: size.width * (0.70 + 0.08 * CGFloat(cos(time * 0.13))),
                     y: size.height * (0.50 + 0.06 * CGFloat(sin(time * 0.19)))),
             Color(hex: 0x39E6FF), size.width * 0.60),
            (CGPoint(x: size.width * (0.45 + 0.05 * CGFloat(sin(time * 0.27))),
                     y: size.height * (0.85 + 0.04 * CGFloat(cos(time * 0.23)))),
             Color(hex: 0xFF3D6E), size.width * 0.50)
        ]
        for (pt, color, r) in blobs {
            var path = Path()
            path.addEllipse(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))
            ctx.fill(path, with: .color(color.opacity(0.45)))
        }
    }
}
