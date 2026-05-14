import AVFoundation

/// Procedural waveforms baked into AVAudioPCMBuffers. Generated once at boot,
/// cached in memory.
enum Waveform {
    case sine, triangle, square, saw
}

struct ToneSpec {
    var frequency: Double       // Hz
    var duration: Double        // s
    var waveform: Waveform = .sine
    var attack: Double = 0.01
    var release: Double = 0.10
    var volume: Float = 0.30
    var detune: Double = 0       // additional stacked oscillator semitones, 0 disables
    var pitchBend: Double = 0    // semitone glide over the duration
}

enum ToneBuilder {
    static let sampleRate: Double = 44100.0

    static func buffer(for spec: ToneSpec) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate, channels: 1
        ) else { return nil }
        let frameCount = AVAudioFrameCount(spec.duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format, frameCapacity: frameCount
        ) else { return nil }
        buffer.frameLength = frameCount

        let channelData = buffer.floatChannelData![0]
        var phase: Double = 0
        var phase2: Double = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let pitch = spec.frequency * pow(2.0, (spec.pitchBend * t / spec.duration) / 12.0)
            let phaseInc = 2.0 * .pi * pitch / sampleRate

            var sample = sampleAt(phase: phase, waveform: spec.waveform)
            if spec.detune != 0 {
                let pitch2 = pitch * pow(2.0, spec.detune / 12.0)
                let phaseInc2 = 2.0 * .pi * pitch2 / sampleRate
                sample = (sample + sampleAt(phase: phase2, waveform: spec.waveform)) * 0.5
                phase2 += phaseInc2
                if phase2 > 2.0 * .pi { phase2 -= 2.0 * .pi }
            }

            // Envelope
            let attackFrames = spec.attack * sampleRate
            let releaseFrames = spec.release * sampleRate
            let envIdx = Double(i)
            let env: Double
            if envIdx < attackFrames {
                env = envIdx / attackFrames
            } else if envIdx > Double(frameCount) - releaseFrames {
                env = max(0, (Double(frameCount) - envIdx) / releaseFrames)
            } else {
                env = 1.0
            }

            channelData[i] = Float(sample) * spec.volume * Float(env)
            phase += phaseInc
            if phase > 2.0 * .pi { phase -= 2.0 * .pi }
        }
        return buffer
    }

    private static func sampleAt(phase: Double, waveform: Waveform) -> Double {
        switch waveform {
        case .sine:     return sin(phase)
        case .triangle: return 2.0 / .pi * asin(sin(phase))
        case .square:   return sin(phase) >= 0 ? 1.0 : -1.0
        case .saw:      return (phase / .pi) - 1.0
        }
    }
}
