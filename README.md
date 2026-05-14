# Neon Tetris

A premium-looking modern Tetris built natively for iPhone with SwiftUI +
SpriteKit. Designed and tuned for the iPhone 17 Air. Targets iOS 17.0 and up.

- 7-bag randomizer, full SRS rotation with wall kicks
- Hold piece, 5-step next queue, soft drop, hard drop with dust burst
- Glassmorphism HUD, animated nebula background, scanline shader
- Per-block neon glow shader, line clear wipe + sparkles
- CoreHaptics feedback, fully procedural synth audio (no media assets needed)
- Pause / resume / restart, persistent personal best
- One-handed gesture controls + on-screen pad

## Quick start

1. Open `NeonTetris.xcodeproj` in Xcode 16 or newer.
2. Pick the `NeonTetris` scheme and a real device or an iPhone 17 Air simulator.
3. Hit ⌘R.

Detailed device install: see [BUILD.md](BUILD.md).
TestFlight distribution: see [TESTFLIGHT.md](TESTFLIGHT.md).
**No Mac, no iPhone?** GitHub Actions can build a Simulator `.app` you can
play in your browser via Appetize.io. See [CI.md](CI.md) for that and for
TestFlight delivery to a real iPhone.

## Project layout

```
NeonTetris.xcodeproj
NeonTetris/
  App/                     # App entry, RootView, coordinator
  Core/                    # Pure game logic — Board, Tetromino, Bag7,
                           # ScoreModel, GameEngine, GameState, HighScoreStore
  Scene/                   # SpriteKit — GameScene, BlockNode,
                           # ParticleEmitters, ShaderLibrary
  UI/                      # SwiftUI screens: Splash, MainMenu, Game,
                           # PauseOverlay, GameOver, Settings, About
  UI/Components/           # NeonButton, GlassPanel, HUDView, AnimatedBackground,
                           # MiniPieceView
  Input/                   # InputController (gesture-to-action), HapticsManager
  Audio/                   # SoundEngine, ToneGenerator
  Settings/                # SettingsStore (@AppStorage backed)
  Resources/Assets.xcassets/   # AppIcon + AccentColor
  Preview Content/         # SwiftUI preview assets
NeonTetrisTests/           # Game engine unit tests
```

The Xcode project uses Xcode 16+ filesystem-synchronized groups, so every
`.swift` file you drop into `NeonTetris/...` is picked up automatically without
re-touching `project.pbxproj`.

## Tech stack

- Swift 5 (Xcode 16 toolchain)
- SwiftUI for screens / menus / HUD
- SpriteKit for the playfield, blocks, particles, screen shake
- Custom GLSL-ES shaders (via `SKShader`) for the animated nebula background,
  scanlines, per-block radial glow and line-clear sweep
- AVAudioEngine driving procedurally generated waveforms — no audio files
- CoreHaptics (with UIKit fallback)
- iOS 17.0 deployment target, builds for arm64 only on device

## Architecture

```
                                ┌──────────────────┐
                                │   AppCoordinator │
                                │  (screen router) │
                                └────────┬─────────┘
        ┌──────────────────────┬─────────┴─────────┬─────────────────┐
        │                      │                   │                 │
   SplashView            MainMenuView         GameView           SettingsView
                                                  │
                  ┌───────────────────────────────┼─────────────────┐
                  │                               │                 │
            GameEngine                    GameScene (SpriteKit)  InputController
            (model, @MainActor              ⇡  ticked via         (gestures →
             ObservableObject)              update(_:); pulls     engine API +
                  │                          state via sync())    HapticsManager)
                  ▼
   board / active / hold / nextQueue / score / state / lastEvent
                  │
                  └──> Combine $lastEvent ──> SoundEngine + HapticsManager + GameScene.consume(event:)
```

`GameEngine` exposes a published `lastEvent: GameEvent?`. The host view
subscribes once and fans the event out to three consumers:

1. `GameScene.consume(event:)` — visual reactions (line wipe, screen shake,
   level-up flash)
2. `SoundEngine.handle(event:)` — procedural synth blip
3. `HapticsManager` — CoreHaptics tap / pulse / multi-pop

This keeps the model pure (no SpriteKit / UIKit imports) and the renderer
declarative (single `sync(with:)` per frame).

## Controls

- Swipe left/right — move one cell per ~half cell drag
- Swipe down — soft drop (also continuous while drag is held downward)
- Strong swipe up — hard drop
- Tap on playfield — rotate clockwise
- ⟳ button — rotate clockwise
- ⤓ big button — hard drop
- ⥥ button — soft drop
- ⏸ top-left — pause
- ⇪ top-right (or HOLD swap) — hold the active piece
- Long tradition: hard drop awards 2 points per row, soft drop awards 1 point per row.

## What is procedurally generated

- All sound effects (`ToneBuilder` → AVAudioPCMBuffer)
- Every neon glow + line clear wipe (SKShader source compiled at runtime)
- The drifting nebula background (shader for the in-game scene; `Canvas` for
  the menu screens)
- The block textures and dust particle textures (`UIGraphicsImageRenderer`)

No `.sks`, `.caf`, `.mp3`, `.wav`, or large `.png` assets are shipped — keeps
the IPA tiny and avoids any third-party content licensing.

## Engineering decisions

These are the choices made for you because the original spec asked the agent
to work autonomously. They are easy to change.

| Decision | Value | Rationale |
|----------|-------|-----------|
| Bundle ID | `com.example.NeonTetris` | Replace with your own. See BUILD.md. |
| Deployment target | iOS 17.0 | Covers iPhone 11 and newer, leaves room for iPhone 17 Air. |
| Orientation (iPhone) | Portrait only | One-handed mobile Tetris convention. |
| Orientation (iPad) | All | Project still works on iPad — bonus. |
| Spawn position | Top of visible row | Mobile players want to see the piece immediately. |
| Lock delay | 0.5 s, real-time accumulated | Resets on every successful move/rotate. |
| Level curve | Standard guideline, capped at 20 | After level 20 gravity stays at ~1 ms/cell. |
| Scoring | 100/300/500/800 × level + combo | Classic guideline. |
| Hold rule | One swap per piece life | Standard Tetris. |
| Top-out | Block on spawn = game over | Standard Tetris. |
| Visual intensity | Low / Medium / High | Lowers shake + halo. Does not reduce particle quality. |
| Audio | `AVAudioSession.ambient .mixWithOthers` | Lets the user keep their music playing. |
| Persistence | UserDefaults | One device, one player — enough for v1. |

## Future improvements

See [TODO.md](TODO.md). None of it is needed for v1 to ship.

## License

This project is provided as a starting point. You own anything you build on
top of it.
