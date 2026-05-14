import SpriteKit
import UIKit

/// A single glowing tetris block. Composed of:
///   1. an outer halo sprite (radial-glow shader)
///   2. a glassy rounded-rect body with neon stroke
///   3. a top highlight line for the glassy feel
final class BlockNode: SKNode {
    static let inset: CGFloat = 1.0

    private let size: CGFloat
    private let halo = SKSpriteNode()
    private let body = SKShapeNode()
    private let highlight = SKShapeNode()
    private(set) var shape: TetrominoShape?

    init(size: CGFloat) {
        self.size = size
        super.init()
        configure()
    }

    required init?(coder aDecoder: NSCoder) { nil }

    private func configure() {
        // Halo — the shader paints the whole sprite, so we keep the base color
        // opaque so SpriteKit does not pre-multiply the shader output by zero.
        // Keep the halo close to the cell footprint so adjacent cells of the
        // same piece don't fuse into one big bright blob (which made the O/I
        // pieces unreadable).
        let haloSize = CGSize(width: size * 1.25, height: size * 1.25)
        halo.size = haloSize
        halo.color = UIColor.white
        halo.colorBlendFactor = 0
        halo.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        halo.blendMode = .add
        addChild(halo)

        // Body: rounded-rect glass
        let bodyRect = CGRect(
            x: -size / 2 + Self.inset, y: -size / 2 + Self.inset,
            width: size - Self.inset * 2, height: size - Self.inset * 2
        )
        body.path = UIBezierPath(
            roundedRect: bodyRect,
            cornerRadius: size * 0.18
        ).cgPath
        body.lineWidth = max(1.0, size * 0.05)
        body.lineJoin = .round
        body.glowWidth = 0.0
        addChild(body)

        // Highlight strip near the top edge for glass feel
        let hlRect = CGRect(
            x: -size / 2 + size * 0.18,
            y: size / 2 - size * 0.30,
            width: size * 0.64, height: size * 0.06
        )
        highlight.path = UIBezierPath(roundedRect: hlRect, cornerRadius: size * 0.03).cgPath
        highlight.lineWidth = 0
        highlight.fillColor = UIColor.white.withAlphaComponent(0.18)
        highlight.blendMode = .add
        addChild(highlight)
    }

    func apply(shape: TetrominoShape, intensity: CGFloat = 1.0) {
        self.shape = shape
        let color = shape.color

        let coreFloat = Self.floatTriplet(from: color.core, mul: 0.55 * intensity)
        // Per-cell halo is intentionally dim — adjacent cells of the same
        // tetromino overlap on additive blend, so a bright halo per cell
        // saturates and the piece reads as one big blob. Keep it low.
        let haloFloat = Self.floatTriplet(from: color.glow, mul: 0.55 * intensity)
        halo.shader = ShaderLibrary.blockEmissive(core: coreFloat, halo: haloFloat)
        halo.color = UIColor.white
        halo.colorBlendFactor = 0

        let coreUI = UIColor(rgb: color.core)
        let glowUI = UIColor(rgb: color.glow)
        body.fillColor = coreUI.mixed(with: .black, ratio: 0.55).withAlphaComponent(0.95)
        body.strokeColor = glowUI
        body.glowWidth = max(1.0, size * 0.08) * intensity

        highlight.isHidden = false
    }

    /// Renders this block as a "ghost" — outline only, no core fill.
    func applyGhost(shape: TetrominoShape) {
        self.shape = shape
        let color = shape.color
        halo.shader = nil
        halo.color = .clear
        body.fillColor = UIColor.clear
        body.strokeColor = UIColor(rgb: color.glow).withAlphaComponent(0.55)
        body.glowWidth = 0
        highlight.isHidden = true
    }

    private static func floatTriplet(from hex: UInt32, mul: CGFloat) -> SIMD3<Float> {
        let r = Float((hex >> 16) & 0xFF) / 255.0 * Float(mul)
        let g = Float((hex >> 8) & 0xFF) / 255.0 * Float(mul)
        let b = Float(hex & 0xFF) / 255.0 * Float(mul)
        return SIMD3<Float>(r, g, b)
    }
}

extension UIColor {
    convenience init(rgb: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    func mixed(with other: UIColor, ratio: CGFloat) -> UIColor {
        let r = max(0, min(1, ratio))
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red:   r1 * (1 - r) + r2 * r,
            green: g1 * (1 - r) + g2 * r,
            blue:  b1 * (1 - r) + b2 * r,
            alpha: a1 * (1 - r) + a2 * r
        )
    }
}
