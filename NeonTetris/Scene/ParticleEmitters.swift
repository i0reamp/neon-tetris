import SpriteKit
import UIKit

/// Programmatic emitters — no .sks asset files required.
enum ParticleEmitters {

    /// Bright sparkle burst used when a line is cleared.
    static func lineClear(color: UIColor, lineWidth: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = makeSoftDot(diameter: 12)
        e.particleBirthRate = 700
        e.numParticlesToEmit = 90
        e.particleLifetime = 0.9
        e.particleLifetimeRange = 0.3
        e.particlePositionRange = CGVector(dx: lineWidth, dy: 6)
        e.particleSpeed = 220
        e.particleSpeedRange = 120
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = .pi * 2
        e.particleAlpha = 0.9
        e.particleAlphaSpeed = -1.0
        e.particleScale = 0.45
        e.particleScaleRange = 0.35
        e.particleScaleSpeed = -0.35
        e.particleColor = color
        e.particleColorBlendFactor = 1.0
        e.particleBlendMode = .add
        e.particleRotation = 0
        e.particleRotationSpeed = 1.0
        return e
    }

    /// Soft white "thump" of dust at the bottom when a piece hard-drops.
    static func hardDropDust(width: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = makeSoftDot(diameter: 18)
        e.particleBirthRate = 400
        e.numParticlesToEmit = 32
        e.particleLifetime = 0.45
        e.particleLifetimeRange = 0.15
        e.particlePositionRange = CGVector(dx: width * 0.9, dy: 2)
        e.particleSpeed = 60
        e.particleSpeedRange = 40
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = .pi / 3
        e.particleAlpha = 0.55
        e.particleAlphaSpeed = -1.4
        e.particleScale = 0.7
        e.particleScaleRange = 0.4
        e.particleScaleSpeed = 0.8
        e.particleColor = UIColor(white: 1.0, alpha: 1.0)
        e.particleColorBlendFactor = 1.0
        e.particleBlendMode = .add
        return e
    }

    /// Small flick when a piece rotates.
    static func rotateFlick(color: UIColor) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = makeSoftDot(diameter: 10)
        e.particleBirthRate = 300
        e.numParticlesToEmit = 14
        e.particleLifetime = 0.35
        e.particleLifetimeRange = 0.1
        e.particlePositionRange = CGVector(dx: 18, dy: 18)
        e.particleSpeed = 90
        e.particleSpeedRange = 40
        e.emissionAngle = 0
        e.emissionAngleRange = .pi * 2
        e.particleAlpha = 0.8
        e.particleAlphaSpeed = -2.0
        e.particleScale = 0.3
        e.particleScaleRange = 0.25
        e.particleScaleSpeed = -0.6
        e.particleColor = color
        e.particleColorBlendFactor = 1.0
        e.particleBlendMode = .add
        return e
    }

    /// Continuous ambient sparkles drifting upward over the playfield.
    static func ambientField(width: CGFloat, height: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = makeSoftDot(diameter: 6)
        e.particleBirthRate = 4
        e.particleLifetime = 6.0
        e.particleLifetimeRange = 2.5
        e.particlePositionRange = CGVector(dx: width, dy: height)
        e.particleSpeed = 12
        e.particleSpeedRange = 6
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = 0.3
        e.particleAlpha = 0.35
        e.particleAlphaSpeed = -0.05
        e.particleScale = 0.4
        e.particleScaleRange = 0.25
        e.particleColor = UIColor(white: 1.0, alpha: 1.0)
        e.particleColorBlendFactor = 1.0
        e.particleBlendMode = .add
        return e
    }

    // MARK: - Texture builders

    private static var cachedDots: [Int: SKTexture] = [:]

    static func makeSoftDot(diameter: CGFloat) -> SKTexture {
        let key = Int(diameter.rounded())
        if let cached = cachedDots[key] { return cached }
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let colors = [
                UIColor.white.cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor
            ] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 1.0])!
            cg.drawRadialGradient(
                grad,
                startCenter: CGPoint(x: diameter / 2, y: diameter / 2), startRadius: 0,
                endCenter: CGPoint(x: diameter / 2, y: diameter / 2), endRadius: diameter / 2,
                options: []
            )
        }
        let tex = SKTexture(image: image)
        cachedDots[key] = tex
        return tex
    }
}
