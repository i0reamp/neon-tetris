import SpriteKit
import UIKit
import Combine

/// SpriteKit scene that renders the playfield, active piece, ghost, particles,
/// and all neon eye-candy. Drives itself off a `GameEngine` through `sync(with:)`
/// and `consume(event:)` calls.
final class GameScene: SKScene {

    // MARK: - Layout
    private(set) var cellSize: CGFloat = 32
    private(set) var boardRect: CGRect = .zero

    // MARK: - Layers
    private let bgLayer = SKNode()
    private let gridLayer = SKNode()
    private let lockedLayer = SKNode()
    private let activeLayer = SKNode()
    private let ghostLayer = SKNode()
    private let effectsLayer = SKNode()

    // MARK: - Persistent visuals
    private var nebulaSprite: SKSpriteNode?
    private var scanlinesSprite: SKSpriteNode?
    private var ambientField: SKEmitterNode?
    private var boardFrame: SKShapeNode?

    // MARK: - Render state
    private var lockedNodes: [[BlockNode?]] = []
    private var activeNodes: [BlockNode] = []
    private var ghostNodes: [BlockNode] = []
    private var lastBoardSignature: Int = 0

    // MARK: - Tuning
    var visualIntensity: VisualIntensity = .high

    // MARK: - Game-loop hook
    private var lastUpdateTime: TimeInterval = 0
    /// Invoked every frame with the delta time. Host sets this to drive the engine.
    var onTick: ((TimeInterval) -> Void)?

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        onTick?(dt)
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.020, green: 0.014, blue: 0.045, alpha: 1.0)
        scaleMode = .resizeFill
        // Force scene size to actual view bounds before any layout call — the
        // initial size we were constructed with (in SceneHolder) does not
        // match the on-device view bounds, and the eventual auto-resize that
        // .resizeFill performs only fires on the *next* present cycle.
        if view.bounds.size != .zero {
            self.size = view.bounds.size
        }
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        view.shouldCullNonVisibleNodes = true

        addChild(bgLayer)
        addChild(gridLayer)
        addChild(lockedLayer)
        addChild(ghostLayer)
        addChild(activeLayer)
        addChild(effectsLayer)
        bgLayer.zPosition = 0
        gridLayer.zPosition = 1
        lockedLayer.zPosition = 3
        ghostLayer.zPosition = 2
        activeLayer.zPosition = 4
        effectsLayer.zPosition = 5

        setupBackground()
        layout()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layout()
    }

    // MARK: - Background

    private func setupBackground() {
        let neb = SKSpriteNode(color: .black, size: size)
        neb.position = CGPoint(x: size.width / 2, y: size.height / 2)
        neb.shader = ShaderLibrary.nebula()
        bgLayer.addChild(neb)
        nebulaSprite = neb

        let scan = SKSpriteNode(color: UIColor(white: 1, alpha: 0.04), size: size)
        scan.position = CGPoint(x: size.width / 2, y: size.height / 2)
        scan.alpha = 0.6
        scan.blendMode = .add
        scan.shader = ShaderLibrary.scanlines()
        bgLayer.addChild(scan)
        scanlinesSprite = scan
    }

    // MARK: - Layout

    private func layout() {
        guard size.width > 0 && size.height > 0 else { return }

        nebulaSprite?.size = size
        nebulaSprite?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        scanlinesSprite?.size = size
        scanlinesSprite?.position = CGPoint(x: size.width / 2, y: size.height / 2)

        let cols = CGFloat(Board.width)
        let rows = CGFloat(Board.visibleHeight)
        let maxW = size.width * 0.92
        let maxH = size.height * 0.92
        cellSize = min(maxW / cols, maxH / rows).rounded(.down)

        let boardW = cellSize * cols
        let boardH = cellSize * rows
        let originX = (size.width - boardW) / 2
        let originY = (size.height - boardH) / 2
        boardRect = CGRect(x: originX, y: originY, width: boardW, height: boardH)

        drawGrid()
        drawBoardFrame()
        installAmbientField()
        rebuildAllNodes()
    }

    private func drawGrid() {
        gridLayer.removeAllChildren()
        let path = UIBezierPath()
        let r = boardRect
        for c in 0...Board.width {
            let x = r.minX + CGFloat(c) * cellSize
            path.move(to: CGPoint(x: x, y: r.minY))
            path.addLine(to: CGPoint(x: x, y: r.maxY))
        }
        for row in 0...Board.visibleHeight {
            let y = r.minY + CGFloat(row) * cellSize
            path.move(to: CGPoint(x: r.minX, y: y))
            path.addLine(to: CGPoint(x: r.maxX, y: y))
        }
        let lines = SKShapeNode(path: path.cgPath)
        lines.strokeColor = UIColor.white.withAlphaComponent(0.05)
        lines.lineWidth = 0.5
        lines.isAntialiased = false
        lines.blendMode = .add
        gridLayer.addChild(lines)
    }

    private func drawBoardFrame() {
        boardFrame?.removeFromParent()
        let rect = boardRect.insetBy(dx: -6, dy: -6)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 14)
        let frame = SKShapeNode(path: path.cgPath)
        frame.strokeColor = UIColor(rgb: 0x6FE7FF, alpha: 0.45)
        frame.lineWidth = 1.5
        frame.glowWidth = 6
        frame.fillColor = UIColor(white: 0.0, alpha: 0.35)
        frame.zPosition = 0.5
        gridLayer.addChild(frame)
        boardFrame = frame
    }

    private func installAmbientField() {
        ambientField?.removeFromParent()
        let e = ParticleEmitters.ambientField(width: size.width, height: size.height)
        e.position = CGPoint(x: size.width / 2, y: 0)
        e.targetNode = self
        e.zPosition = 0.2
        bgLayer.addChild(e)
        ambientField = e
    }

    // MARK: - Coordinate transforms

    private func cellCenter(x: Int, y: Int) -> CGPoint {
        // Engine y=0 is the top of the playfield (incl. hidden rows). The
        // visible board starts at y = hiddenRows. SpriteKit y is up.
        let yVisible = CGFloat(y - Board.hiddenRows)
        let px = boardRect.minX + (CGFloat(x) + 0.5) * cellSize
        let py = boardRect.maxY - (yVisible + 0.5) * cellSize
        return CGPoint(x: px, y: py)
    }

    // MARK: - Public API

    func sync(with engine: GameEngine) {
        // Locked cells (only visible rows are rendered).
        ensureLockedGrid()
        for y in 0..<Board.height {
            for x in 0..<Board.width {
                let cell = engine.board.cells[y][x]
                if y < Board.hiddenRows {
                    if let n = lockedNodes[y][x] {
                        n.removeFromParent()
                        lockedNodes[y][x] = nil
                    }
                    continue
                }
                switch cell {
                case .empty:
                    if let n = lockedNodes[y][x] {
                        n.removeFromParent()
                        lockedNodes[y][x] = nil
                    }
                case .filled(let shape):
                    let node = lockedNodes[y][x] ?? makeBlockNode()
                    if node.parent == nil {
                        lockedLayer.addChild(node)
                    }
                    node.position = cellCenter(x: x, y: y)
                    if node.shape != shape {
                        node.apply(shape: shape, intensity: intensityMultiplier())
                    }
                    lockedNodes[y][x] = node
                }
            }
        }

        // Active piece (hide cells that are still in the hidden rows above the
        // visible playfield to avoid bleed-through).
        for n in activeNodes { n.removeFromParent() }
        activeNodes.removeAll()
        if let piece = engine.active {
            for cell in piece.cells() where cell.y >= Board.hiddenRows {
                let n = makeBlockNode()
                n.apply(shape: piece.shape, intensity: intensityMultiplier())
                n.position = cellCenter(x: cell.x, y: cell.y)
                activeLayer.addChild(n)
                activeNodes.append(n)
            }
        }

        // Ghost
        for n in ghostNodes { n.removeFromParent() }
        ghostNodes.removeAll()
        if let piece = engine.active {
            let ghost = engine.board.ghost(for: piece)
            if ghost.origin != piece.origin {
                for cell in ghost.cells() where cell.y >= Board.hiddenRows {
                    let n = makeBlockNode()
                    n.applyGhost(shape: piece.shape)
                    n.position = cellCenter(x: cell.x, y: cell.y)
                    ghostLayer.addChild(n)
                    ghostNodes.append(n)
                }
            }
        }
    }

    func consume(event: GameEvent) {
        switch event {
        case .rotated(true):
            playRotateEffect()
        case .hardDrop(let rows):
            playHardDropEffect(rows: rows)
        case .locked:
            screenShake(magnitude: 1.5, duration: 0.05)
        case .linesClearing(let rows):
            pulseClearingRows(rows: rows)
            playLineClearEffect(rows: rows)
        case .linesCleared(_, let kind):
            if kind == .tetris {
                screenShake(magnitude: 8, duration: 0.18)
                playTetrisFlash()
            } else if kind != .none {
                screenShake(magnitude: 3, duration: 0.1)
            }
        case .levelUp:
            playLevelUpFlash()
        case .gameOver:
            playGameOverFade()
        default:
            break
        }
    }

    // MARK: - Helpers

    private func ensureLockedGrid() {
        if lockedNodes.count != Board.height {
            for row in lockedNodes { for n in row { n?.removeFromParent() } }
            lockedNodes = Array(
                repeating: Array(repeating: nil, count: Board.width),
                count: Board.height
            )
        }
    }

    private func makeBlockNode() -> BlockNode {
        BlockNode(size: cellSize)
    }

    private func rebuildAllNodes() {
        for row in lockedNodes { for n in row { n?.removeFromParent() } }
        lockedNodes = []
        for n in activeNodes { n.removeFromParent() }
        activeNodes.removeAll()
        for n in ghostNodes { n.removeFromParent() }
        ghostNodes.removeAll()
    }

    private func intensityMultiplier() -> CGFloat {
        switch visualIntensity {
        case .low: return 0.65
        case .medium: return 0.85
        case .high: return 1.0
        }
    }

    // MARK: - Effects

    private func playRotateEffect() {
        guard !activeNodes.isEmpty, visualIntensity != .low else { return }
        let centerY = activeNodes.map { $0.position.y }.reduce(0, +) / CGFloat(activeNodes.count)
        let centerX = activeNodes.map { $0.position.x }.reduce(0, +) / CGFloat(activeNodes.count)
        let shape = activeNodes.first?.shape ?? .T
        let emitter = ParticleEmitters.rotateFlick(color: UIColor(rgb: shape.color.glow))
        emitter.position = CGPoint(x: centerX, y: centerY)
        effectsLayer.addChild(emitter)
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.removeFromParent()
        ]))
    }

    private func playHardDropEffect(rows: Int) {
        guard !activeNodes.isEmpty else { return }
        let minY = activeNodes.map { $0.position.y }.min() ?? 0
        let centerX = activeNodes.map { $0.position.x }.reduce(0, +) / CGFloat(activeNodes.count)
        let dust = ParticleEmitters.hardDropDust(width: cellSize * 4)
        dust.position = CGPoint(x: centerX, y: minY - cellSize * 0.5)
        effectsLayer.addChild(dust)
        dust.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.removeFromParent()
        ]))
        screenShake(magnitude: CGFloat(min(rows, 12)) * 0.6, duration: 0.10)
    }

    private func pulseClearingRows(rows: [Int]) {
        for row in rows where lockedNodes.indices.contains(row) {
            for x in 0..<Board.width {
                guard let node = lockedNodes[row][x], node.action(forKey: "clearPulse") == nil else { continue }
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.25, duration: 0.10),
                    SKAction.scale(to: 0.0, duration: 0.16)
                ])
                node.run(pulse, withKey: "clearPulse")
            }
        }
    }

    private func playLineClearEffect(rows: [Int]) {
        for row in rows {
            let centerY = cellCenter(x: 0, y: row).y
            let strip = SKSpriteNode(color: .white, size: CGSize(width: boardRect.width, height: cellSize))
            strip.position = CGPoint(x: boardRect.midX, y: centerY)
            strip.zPosition = 4.5
            strip.blendMode = .add
            let wipe = ShaderLibrary.lineClearWipe()
            strip.shader = wipe

            // Animate the shader's progress uniform.
            let duration: TimeInterval = 0.35
            let action = SKAction.customAction(withDuration: duration) { _, t in
                let progress = Float(min(1.0, t / CGFloat(duration)))
                wipe.uniformNamed("u_progress")?.floatValue = progress
            }
            strip.run(SKAction.sequence([
                action,
                SKAction.fadeOut(withDuration: 0.05),
                SKAction.removeFromParent()
            ]))
            effectsLayer.addChild(strip)

            // Sparkles
            let color = pickColorForRow(row) ?? UIColor(rgb: 0xFFFFFF)
            let burst = ParticleEmitters.lineClear(color: color, lineWidth: boardRect.width)
            burst.position = CGPoint(x: boardRect.midX, y: centerY)
            effectsLayer.addChild(burst)
            burst.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.2),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func pickColorForRow(_ row: Int) -> UIColor? {
        let r = lockedNodes.indices.contains(row) ? lockedNodes[row] : []
        for n in r {
            if let s = n?.shape { return UIColor(rgb: s.color.glow) }
        }
        return nil
    }

    private func playTetrisFlash() {
        let flash = SKSpriteNode(color: UIColor(rgb: 0xFFFFFF, alpha: 0.55), size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 6
        flash.alpha = 0
        effectsLayer.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.55, duration: 0.05),
            SKAction.fadeOut(withDuration: 0.35),
            SKAction.removeFromParent()
        ]))
    }

    private func playLevelUpFlash() {
        let flash = SKSpriteNode(color: UIColor(rgb: 0x6FE7FF, alpha: 0.30), size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 6
        flash.alpha = 0
        flash.blendMode = .add
        effectsLayer.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.30, duration: 0.06),
            SKAction.fadeOut(withDuration: 0.45),
            SKAction.removeFromParent()
        ]))
    }

    private func playGameOverFade() {
        let veil = SKSpriteNode(color: UIColor(red: 0.6, green: 0.02, blue: 0.18, alpha: 0.0), size: size)
        veil.position = CGPoint(x: size.width / 2, y: size.height / 2)
        veil.zPosition = 6
        effectsLayer.addChild(veil)
        veil.run(SKAction.fadeAlpha(to: 0.30, duration: 0.4))
    }

    private func screenShake(magnitude: CGFloat, duration: TimeInterval) {
        guard visualIntensity != .low else { return }
        let amount = magnitude * (visualIntensity == .high ? 1.0 : 0.6)
        let count = max(2, Int(duration * 30))
        var actions: [SKAction] = []
        for _ in 0..<count {
            let dx = CGFloat.random(in: -amount...amount)
            let dy = CGFloat.random(in: -amount...amount)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: duration / Double(count)))
            actions.append(SKAction.moveBy(x: -dx, y: -dy, duration: duration / Double(count)))
        }
        let group = SKNode()
        run(SKAction.sequence(actions))
        _ = group
    }
}

enum VisualIntensity: String, CaseIterable, Codable {
    case low, medium, high
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}
