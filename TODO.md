# TODO — nice to have, not blocking v1

Everything in v1 already meets the brief. This list captures polish work
that would be nice to add later. Nothing here is a hole in the shipping
build.

## Game

- [ ] T-spin detection and bonus scoring (T-spin single/double/triple)
- [ ] Back-to-back tetris / T-spin multiplier
- [ ] DAS / ARR settings (currently fixed at "snap each half-cell drag")
- [ ] Sprint mode (40 lines)
- [ ] Marathon vs. endless mode toggle
- [ ] Configurable starting level
- [ ] Garbage / battle mode (multiplayer over Game Center)
- [ ] Replay system / share replay link

## Visuals

- [ ] Real Tetris animation when a hold swap happens (current swap is instant)
- [ ] Subtle reflection in the block "glass" highlight
- [ ] Particle burst variants per shape colour (currently colour is per row)
- [ ] Idle animation on Main Menu (a piece falling in the background)
- [ ] Light theme / accessibility high-contrast theme
- [ ] Reduced-motion mode that disables screen shake & background motion

## Audio

- [ ] Procedurally generated chiptune background track (currently silent
      between events)
- [ ] Music ducking when an event SFX plays
- [ ] Optional licensed soundtrack drop-in (see ASSETS.md for the recipe)

## UX / polish

- [ ] Tutorial overlay for first launch
- [ ] In-game pause/resume slide animation polish
- [ ] Localisation: only English strings exist
- [ ] VoiceOver labels on all controls
- [ ] Dynamic Type respect in HUD typography

## Tooling

- [ ] Fastlane setup for `fastlane beta` → TestFlight one-liner
- [ ] Automated `xcrun simctl io ... screenshot` pipeline (see
      Screenshots/README.md)
- [ ] SwiftLint / SwiftFormat configuration
- [ ] GitHub Actions: build + test on every PR
- [ ] Crashlytics or Apple's metrics hook (currently zero analytics)

## Engineering debt

- [ ] Convert `GameEngine` to use the iOS 17 `Observation` `@Observable`
      macro instead of `ObservableObject` + `@Published`
- [ ] Move the SKShader sources to text resource files instead of string
      literals (better syntax highlighting)
- [ ] Build a single Test Plan that wires the Tests target into the scheme
      properly (currently the scheme picks it up but a `.xctestplan` would
      let us run UI tests too)
- [ ] App Icon at all sizes — only the marketing 1024 slot is wired
