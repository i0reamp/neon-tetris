# Assets

Neon Tetris is deliberately **asset-free** at runtime — everything is either
generated procedurally or drawn with SwiftUI / SpriteKit primitives. The
table below summarises what each visual or sound element is generated from,
and where you'd plug in a custom asset if you wanted to.

## Visuals

| Element | Source | How to override |
|---------|--------|-----------------|
| App icon | Empty `AppIcon.appiconset` (Xcode uses a transparent placeholder) | Drop a 1024×1024 PNG into `NeonTetris/Resources/Assets.xcassets/AppIcon.appiconset/`, then update the matching `Contents.json` entry. |
| Accent color | `AccentColor` color set (`#6FE7FF`) | Edit the colorset JSON. |
| Animated background (menu) | `AnimatedBackground` SwiftUI canvas with timeline blobs | Replace `AnimatedBackground` body. |
| Animated background (gameplay) | `ShaderLibrary.nebula()` SKShader | Edit the GLSL source string. |
| Scanlines / shimmer | `ShaderLibrary.scanlines()` SKShader | Edit the GLSL source. |
| Per-block neon glow | `ShaderLibrary.blockEmissive(core:halo:)` SKShader | Edit the GLSL source / change the per-shape colors in `TetrominoShape.color`. |
| Glassy block body | `BlockNode` SKShapeNode with rounded rect | Replace `body.path` and stroke/fill. |
| Line clear wipe | `ShaderLibrary.lineClearWipe()` SKShader, driven by a uniform | Edit the GLSL source. |
| Line clear sparkles | `ParticleEmitters.lineClear(...)` programmatic SKEmitterNode | Edit the emitter settings or replace with an `.sks` file. |
| Hard drop dust | `ParticleEmitters.hardDropDust(...)` | Same. |
| Rotate flicks | `ParticleEmitters.rotateFlick(...)` | Same. |
| Ambient drifting sparkles | `ParticleEmitters.ambientField(...)` | Same. |
| Glass UI panels | `GlassPanel` (SwiftUI `.ultraThinMaterial` + gradient + stroke) | Edit `GlassPanel`. |
| Neon buttons | `NeonButton` | Edit `NeonButton`. |

### Tetromino color palette

Defined in `TetrominoShape.color`:

| Shape | Core | Halo |
|-------|------|------|
| I | `#00F0FF` | `#60FFFF` |
| O | `#FFE100` | `#FFF59A` |
| T | `#C04CFF` | `#E39CFF` |
| S | `#39FF7A` | `#9CFFB8` |
| Z | `#FF3D6E` | `#FF9AB1` |
| J | `#3A7BFF` | `#9CB8FF` |
| L | `#FFA12B` | `#FFD79A` |

Override per shape if you want a different palette.

## Audio

All sound effects are procedurally synthesised at app boot via
`ToneBuilder.buffer(for:)`. The buffers are cached in `SoundEngine.buffers`.
Specs live in `SoundEngine.bakeBuffers()`.

| Cue | Default tone |
|-----|--------------|
| Move | 320 Hz sine, 50 ms |
| Rotate | 540 Hz triangle, 60 ms, +4 semitone glide |
| Soft drop | 220 Hz sine, 40 ms |
| Hard drop | 90 Hz saw, 180 ms, −5 semitone glide |
| Lock | 150 Hz square, 100 ms |
| Single line | 660 Hz triangle, 180 ms, +3 semitone glide |
| Double line | 720 Hz triangle, 220 ms, +5 semitones |
| Triple line | 800 Hz triangle, 260 ms, +7 semitones |
| Tetris | 990 Hz triangle, 360 ms, +9 semitones, detuned at +7 |
| Level up | 1320 Hz sine, 400 ms, +12 semitones |
| Game over | 220 Hz saw, 900 ms, −12 semitones |
| Hold | 480 Hz triangle, 60 ms, −3 semitones |
| Menu open | 720 Hz sine, 200 ms, +5 semitones |
| Menu confirm | 880 Hz triangle, 200 ms, +7 semitones |

### Plugging in real audio files

1. Drop the file (`.caf` or `.wav` preferred for low latency) into
   `NeonTetris/Audio/` (the synced group picks it up automatically).
2. In `SoundEngine`, load it as a buffer:

   ```swift
   let url = Bundle.main.url(forResource: "line_clear_4", withExtension: "caf")!
   let file = try AVAudioFile(forReading: url)
   let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                              frameCapacity: AVAudioFrameCount(file.length))!
   try file.read(into: buf)
   buffers[.lineClear(4)] = buf
   ```

3. Skip the matching entry in `bakeBuffers()`.

## Haptics

All haptic events are CoreHaptics continuous events whose intensity /
sharpness / duration are set in code. See `HapticsManager`. There are no
external `.ahap` files; if you want to author custom patterns:

1. Author a `.ahap` JSON file (e.g. in the Haptic Pattern editor).
2. Drop it into `NeonTetris/Input/`.
3. Load via `try CHHapticPattern(contentsOf: url)` and play with
   `engine.makePlayer(with:)`.

## Screenshots

See [Screenshots/README.md](Screenshots/README.md) for the manual capture
flow until automated screenshots are added (this is a TODO item).
