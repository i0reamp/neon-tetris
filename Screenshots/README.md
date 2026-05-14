# Screenshots

The project currently ships **no pre-baked screenshots**. Reason: the agent
authoring this project ran on Linux and could not boot the iOS Simulator, so
it cannot produce real device captures.

Until automation is wired up (see TODO.md), use the recipe below.

## Manual capture, App Store / TestFlight style

You need: macOS, Xcode 16+, project built clean.

1. Boot the iOS Simulator with the device you want:
   ```bash
   xcrun simctl boot "iPhone 17 Air"
   open -a Simulator
   ```
2. From Xcode, build & run Neon Tetris on that simulator (⌘R).
3. Reach the screen you want to capture:
   - Main menu — opens automatically after the splash.
   - Game — tap PLAY.
   - Line clear — play long enough to set up a line clear and screenshot
     while the wipe shader is mid-animation.
   - Pause — tap the pause icon top-left.
   - Settings — Main Menu → Settings.
   - Game Over — let a game end (or stack quickly).
4. Capture each frame with the OS command, saving into this folder:
   ```bash
   mkdir -p Screenshots
   xcrun simctl io booted screenshot --type=png Screenshots/01-main-menu.png
   xcrun simctl io booted screenshot --type=png Screenshots/02-gameplay.png
   xcrun simctl io booted screenshot --type=png Screenshots/03-line-clear.png
   xcrun simctl io booted screenshot --type=png Screenshots/04-pause-or-settings.png
   xcrun simctl io booted screenshot --type=png Screenshots/05-game-over.png
   ```
5. Optionally mask the status bar bezel or use Apple's [Marketing
   templates](https://developer.apple.com/app-store/marketing/guidelines/) to
   compose marketing-style screenshots.

## iPhone 17 Air mockup notes

For marketing visuals, target a 6.9" Super Retina XDR display. Suggested
target resolutions (iPhone 17 Air follows the iPhone 17 Pro Max format):

- 1290 × 2796 px portrait (App Store required size)

You can also use `Screenshots/05-game-over.png` etc. as raw inputs and drop
them into a device frame in Sketch/Figma. Apple provides device frames at
<https://developer.apple.com/design/resources/>.

## Automating it later

The TODO list calls for a real screenshot pipeline:

1. Add UI tests that drive the app to each screen.
2. Use `XCUIScreen.main.screenshot()` inside the UI tests with an
   `XCTAttachment` of type `.screenshot, lifetime: .keepAlways`.
3. Wrap it in a Fastlane lane:

   ```ruby
   lane :snap do
     capture_screenshots(scheme: "NeonTetris")
   end
   ```

That gets you per-device, per-locale captures with no manual clicks.
