import Foundation
import AVFoundation

@MainActor
final class SoundEngine {
    static let shared = SoundEngine()

    var isEnabled: Bool = true

    private let engine = AVAudioEngine()
    private var mixer: AVAudioMixerNode { engine.mainMixerNode }
    private var players: [SoundCue: [AVAudioPlayerNode]] = [:]
    private var buffers: [SoundCue: AVAudioPCMBuffer] = [:]
    private let playersPerCue = 3
    private var started = false

    enum SoundCue: Hashable {
        case move, rotate, softDrop, hardDrop, lock, lineClear(Int), levelUp, gameOver, hold, menuOpen, menuConfirm
    }

    private init() {
        configureSession()
        bakeBuffers()
        start()
    }

    // MARK: - Setup

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            // best-effort
        }
    }

    private func bakeBuffers() {
        let specs: [(SoundCue, ToneSpec)] = [
            (.move, ToneSpec(frequency: 320, duration: 0.05, waveform: .sine, attack: 0.001, release: 0.03, volume: 0.18)),
            (.rotate, ToneSpec(frequency: 540, duration: 0.06, waveform: .triangle, attack: 0.002, release: 0.04, volume: 0.22, pitchBend: 4)),
            (.softDrop, ToneSpec(frequency: 220, duration: 0.04, waveform: .sine, attack: 0.001, release: 0.03, volume: 0.14)),
            (.hardDrop, ToneSpec(frequency: 90, duration: 0.18, waveform: .saw, attack: 0.001, release: 0.14, volume: 0.30, pitchBend: -5)),
            (.lock, ToneSpec(frequency: 150, duration: 0.10, waveform: .square, attack: 0.001, release: 0.06, volume: 0.18)),
            (.lineClear(1), ToneSpec(frequency: 660, duration: 0.18, waveform: .triangle, attack: 0.002, release: 0.12, volume: 0.30, pitchBend: 3)),
            (.lineClear(2), ToneSpec(frequency: 720, duration: 0.22, waveform: .triangle, attack: 0.002, release: 0.14, volume: 0.32, pitchBend: 5)),
            (.lineClear(3), ToneSpec(frequency: 800, duration: 0.26, waveform: .triangle, attack: 0.002, release: 0.16, volume: 0.34, pitchBend: 7)),
            (.lineClear(4), ToneSpec(frequency: 990, duration: 0.36, waveform: .triangle, attack: 0.002, release: 0.22, volume: 0.40, detune: 7, pitchBend: 9)),
            (.levelUp, ToneSpec(frequency: 1320, duration: 0.40, waveform: .sine, attack: 0.005, release: 0.30, volume: 0.32, pitchBend: 12)),
            (.gameOver, ToneSpec(frequency: 220, duration: 0.90, waveform: .saw, attack: 0.005, release: 0.6, volume: 0.32, pitchBend: -12)),
            (.hold, ToneSpec(frequency: 480, duration: 0.06, waveform: .triangle, attack: 0.001, release: 0.04, volume: 0.18, pitchBend: -3)),
            (.menuOpen, ToneSpec(frequency: 720, duration: 0.20, waveform: .sine, attack: 0.005, release: 0.18, volume: 0.18, pitchBend: 5)),
            (.menuConfirm, ToneSpec(frequency: 880, duration: 0.20, waveform: .triangle, attack: 0.005, release: 0.18, volume: 0.22, pitchBend: 7))
        ]
        for (cue, spec) in specs {
            if let buffer = ToneBuilder.buffer(for: spec) {
                buffers[cue] = buffer
            }
        }
    }

    private func start() {
        guard !started else { return }
        // Attach a small pool of players per cue so overlapping events do not cut each other.
        for cue in buffers.keys {
            var pool: [AVAudioPlayerNode] = []
            for _ in 0..<playersPerCue {
                let p = AVAudioPlayerNode()
                engine.attach(p)
                engine.connect(p, to: mixer, format: buffers[cue]?.format)
                pool.append(p)
            }
            players[cue] = pool
        }
        do {
            try engine.start()
            started = true
        } catch {
            // ignore — game still plays without audio
        }
    }

    // MARK: - Public

    func play(_ cue: SoundCue, volume: Float = 1.0) {
        guard isEnabled, started else { return }
        let lookup: SoundCue
        if case .lineClear(let n) = cue {
            lookup = .lineClear(max(1, min(4, n)))
        } else {
            lookup = cue
        }
        guard let buf = buffers[lookup], let pool = players[lookup] else { return }
        let node = pool.first(where: { !$0.isPlaying }) ?? pool.first!
        node.volume = volume
        node.scheduleBuffer(buf, at: nil, options: [.interrupts], completionHandler: nil)
        if !node.isPlaying { node.play() }
    }

    func handle(event: GameEvent) {
        switch event {
        case .moved: play(.move)
        case .rotated(true): play(.rotate)
        case .softDrop: play(.softDrop, volume: 0.6)
        case .hardDrop: play(.hardDrop)
        case .locked: play(.lock)
        case .linesCleared(let count, _): play(.lineClear(count))
        case .levelUp: play(.levelUp)
        case .gameOver: play(.gameOver)
        case .holdSwap: play(.hold)
        default: break
        }
    }
}
