# Changelog

All notable changes to Neon Tetris will be documented here. The format
loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-05-14

Initial public build.

### Added
- Full classic Tetris ruleset
  - All 7 tetrominoes
  - 7-bag randomizer
  - SRS rotation with full wall-kick table (separate I-piece table)
  - Soft drop, hard drop, hold-piece, ghost piece
  - 5-step next queue
  - Real-time lock delay with reset on movement
  - Level curve, gravity curve up to level 20
  - Guideline scoring (100/300/500/800 × level + combo bonus)
  - Top-out game-over detection
- Premium neon visual style
  - SpriteKit playfield rendered with custom shaders
  - Per-block radial neon glow + glassy core + edge stroke
  - Animated nebula background shader
  - Scanline shimmer overlay
  - Line clear "wipe" shader with sparkle burst per row
  - Hard drop dust particles + screen shake
  - Tetris-clear screen flash
  - Ambient drifting sparkles overlay
- SwiftUI screens: Splash, Main Menu, Game, Pause, Game Over, Settings, About
- Glass panel HUD with Score / Lines / Level + Hold + Next queue
- Procedural sound engine (AVAudioEngine + custom waveform builder)
- CoreHaptics integration with UIKit fallback
- One-handed controls: drag to move, swipe up = hard drop, tap = rotate,
  separate on-screen control pad
- Persistent personal best (UserDefaults)
- Settings: sound, haptics, visual intensity (low/medium/high), reset records
- Xcode 16 file-system synchronized project layout — no manual `.pbxproj`
  fiddling needed when adding files
- Unit tests covering bag randomization, engine spawn / move / hold / level

### Engineering notes
- Targets iOS 17.0 and up
- Built for iPhone 17 Air, runs on any iPhone 11 or newer
- No bundled audio or image assets — everything is generated at runtime
- Bundle ID placeholder: `com.example.NeonTetris` — must be replaced before
  uploading to App Store Connect
