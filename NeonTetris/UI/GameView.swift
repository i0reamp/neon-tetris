import SwiftUI
import SpriteKit
import Combine

@MainActor
final class SceneHolder: ObservableObject {
    let scene: GameScene
    init() {
        scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.scaleMode = .resizeFill
    }
}

struct GameView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var settings: SettingsStore

    @StateObject private var engine = GameEngine()
    @StateObject private var sceneHolder = SceneHolder()
    @StateObject private var inputHolder = InputHolder()

    @State private var subscriptions = Set<AnyCancellable>()
    @State private var showingPauseOverlay = false
    @State private var wired = false
    @State private var lastClearKind: LineClearKind? = nil
    @State private var clearBannerVisible = false

    var body: some View {
        ZStack(alignment: .top) {
            spriteLayer
                .ignoresSafeArea()

            // Top HUD — anchored to top edge of safe area.
            topBar
                .padding(.top, 8)
                .padding(.horizontal, 16)

            // Bottom HUD + controls — anchored to bottom edge of safe area.
            VStack(spacing: 6) {
                HUDView(engine: engine)
                bottomControls
                    .padding(.horizontal, 14)
            }
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            // Clear announcement banner
            if let kind = lastClearKind, clearBannerVisible, kind != .none {
                ClearBanner(kind: kind)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if showingPauseOverlay {
                PauseOverlayView(
                    onResume: { resumeGame() },
                    onRestart: {
                        engine.start()
                        showingPauseOverlay = false
                    },
                    onMenu: { coordinator.go(to: .mainMenu) }
                )
                .transition(.opacity.combined(with: .scale))
            }

            if engine.state == .gameOver {
                GameOverView(engine: engine,
                             onRestart: { engine.start() },
                             onMenu: { coordinator.go(to: .mainMenu) })
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { wireUpOnce() }
        .gesture(panGesture)
        .simultaneousGesture(tapGesture)
    }

    // MARK: - Sprite layer

    private var spriteLayer: some View {
        GeometryReader { geo in
            SpriteView(
                scene: sceneHolder.scene,
                preferredFramesPerSecond: 60,
                options: [.ignoresSiblingOrder, .allowsTransparency]
            )
            .background(Color(hex: 0x05040D))
            .onAppear {
                sceneHolder.scene.size = geo.size
                sceneHolder.scene.visualIntensity = settings.visualIntensity
                // Update input cellSize on the next runloop pass once layout has run.
                DispatchQueue.main.async {
                    inputHolder.controller?.cellSize = sceneHolder.scene.cellSize
                }
            }
            .onChange(of: geo.size) { _, newSize in
                sceneHolder.scene.size = newSize
                DispatchQueue.main.async {
                    inputHolder.controller?.cellSize = sceneHolder.scene.cellSize
                }
            }
            .onChange(of: settings.visualIntensity) { _, newValue in
                sceneHolder.scene.visualIntensity = newValue
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button { pauseGame() } label: {
                IconChip(systemName: "pause.fill", tint: Color(hex: 0xFFA12B))
            }
            Spacer()
            Button { inputHolder.controller?.holdAction() } label: {
                IconChip(systemName: "tray.and.arrow.down.fill", tint: Color(hex: 0xC04CFF))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        HStack(spacing: 12) {
            CircleControlButton(systemName: "arrow.left", tint: Color(hex: 0x39E6FF)) {
                engine.moveLeft()
                HapticsManager.shared.move()
            }
            CircleControlButton(systemName: "arrow.down", tint: Color(hex: 0x39FF7A)) {
                engine.softDropOnce()
            }
            CircleControlButton(systemName: "arrow.right", tint: Color(hex: 0x39E6FF)) {
                engine.moveRight()
                HapticsManager.shared.move()
            }
            Spacer()
            CircleControlButton(systemName: "arrow.clockwise", tint: Color(hex: 0xFFE100)) {
                inputHolder.controller?.tapToRotate()
            }
            CircleControlButton(systemName: "arrow.down.to.line", tint: Color(hex: 0xFF3D6E), big: true) {
                inputHolder.controller?.hardDropAction()
            }
        }
    }

    // MARK: - Gestures

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                inputHolder.controller?.panChanged(translation: value.translation)
            }
            .onEnded { value in
                let vx = (value.predictedEndLocation.x - value.location.x) * 4
                let vy = (value.predictedEndLocation.y - value.location.y) * 4
                inputHolder.controller?.panEnded(translation: value.translation,
                                                 velocity: CGSize(width: vx, height: vy))
            }
    }

    private var tapGesture: some Gesture {
        SpatialTapGesture(count: 1)
            .onEnded { ev in
                let h = UIScreen.main.bounds.height
                // Ignore taps near the HUD areas
                if ev.location.y < 110 || ev.location.y > h - 260 { return }
                inputHolder.controller?.tapToRotate()
            }
    }

    // MARK: - Wiring

    private func wireUpOnce() {
        guard !wired else { return }
        wired = true

        let ic = InputController(engine: engine, settings: settings)
        ic.cellSize = sceneHolder.scene.cellSize
        inputHolder.controller = ic

        sceneHolder.scene.onTick = { [scene = sceneHolder.scene, engine] dt in
            engine.tick(deltaTime: dt)
            scene.sync(with: engine)
        }

        engine.$lastEvent
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [scene = sceneHolder.scene] event in
                scene.consume(event: event)
                SoundEngine.shared.handle(event: event)
                Self.forwardHaptic(event: event)
                forwardBanner(event: event)
            }
            .store(in: &subscriptions)

        engine.start()
    }

    private func pauseGame() {
        engine.pause()
        withAnimation(.easeInOut(duration: 0.25)) {
            showingPauseOverlay = true
        }
    }

    private func resumeGame() {
        engine.resume()
        withAnimation(.easeInOut(duration: 0.25)) {
            showingPauseOverlay = false
        }
    }

    private func forwardBanner(event: GameEvent) {
        if case .linesCleared(_, let kind) = event, kind != .none {
            lastClearKind = kind
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                clearBannerVisible = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 850_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.4)) {
                        clearBannerVisible = false
                    }
                }
            }
        }
    }

    static func forwardHaptic(event: GameEvent) {
        switch event {
        case .moved: HapticsManager.shared.move()
        case .rotated(true): HapticsManager.shared.rotate()
        case .softDrop: HapticsManager.shared.softDrop()
        case .hardDrop: HapticsManager.shared.hardDrop()
        case .holdSwap: HapticsManager.shared.hold()
        case .linesCleared(let count, let kind):
            if kind == .tetris { HapticsManager.shared.tetris() }
            else { HapticsManager.shared.lineClear(count: count) }
        case .levelUp: HapticsManager.shared.levelUp()
        case .gameOver: HapticsManager.shared.gameOver()
        default: break
        }
    }
}

@MainActor
final class InputHolder: ObservableObject {
    @Published var controller: InputController?
}

private struct ClearBanner: View {
    let kind: LineClearKind

    var body: some View {
        Text(kind.displayName)
            .font(.system(size: 36, weight: .black, design: .rounded))
            .tracking(8)
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, accent],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .shadow(color: accent.opacity(0.95), radius: 18)
            .shadow(color: accent.opacity(0.5), radius: 36)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(accent, lineWidth: 1.2)
            )
    }

    private var accent: Color {
        switch kind {
        case .single: return Color(hex: 0x39E6FF)
        case .double: return Color(hex: 0x39FF7A)
        case .triple: return Color(hex: 0xC04CFF)
        case .tetris: return Color(hex: 0xFFE100)
        case .none: return .white
        }
    }
}

private struct IconChip: View {
    let systemName: String
    let tint: Color
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(.white)
            .padding(14)
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().stroke(tint.opacity(0.7), lineWidth: 1.2))
                    .shadow(color: tint.opacity(0.55), radius: 10)
            }
    }
}

struct CircleControlButton: View {
    let systemName: String
    let tint: Color
    var big: Bool = false
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button { action() } label: {
            Image(systemName: systemName)
                .font(.system(size: big ? 26 : 20, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: big ? 78 : 58, height: big ? 78 : 58)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle().fill(
                                LinearGradient(colors: [tint.opacity(0.35), tint.opacity(0.05)],
                                               startPoint: .top, endPoint: .bottom)
                            )
                        )
                        .overlay(Circle().stroke(tint, lineWidth: 1.3))
                        .shadow(color: tint.opacity(0.65), radius: big ? 16 : 10)
                }
                .scaleEffect(pressed ? 0.93 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded { _ in pressed = false })
    }
}
