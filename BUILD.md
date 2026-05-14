# Building & Running Neon Tetris

## Prerequisites

- macOS Sequoia 15 or newer (Xcode 16 requires it)
- Xcode 16.0 or newer
- An Apple ID — free is fine for development on your own device, paid Apple
  Developer Program is required for TestFlight or Ad Hoc distribution

## 1. Open the project

1. Unzip / clone this folder.
2. Double-click `NeonTetris.xcodeproj`. Xcode opens.
3. Select the `NeonTetris` scheme (top of the window, left of the device picker).

> If Xcode warns "project requires a newer version of Xcode", you are on an
> older Xcode. Update via the App Store.

## 2. Set the Bundle Identifier

The project ships with `com.example.NeonTetris`. Replace it with one tied to
your Apple ID:

1. Click the `NeonTetris` project root in the file navigator.
2. Pick the `NeonTetris` target → `Signing & Capabilities`.
3. Change `Bundle Identifier` to something like
   `com.<yourname>.neontetris`. Use lowercase letters, digits and dots only.
4. Repeat for the `NeonTetrisTests` target (the test bundle identifier just
   needs to be unique inside your team — e.g. append `.tests`).

## 3. Pick a Team

In `Signing & Capabilities` for the `NeonTetris` target:

1. Check **Automatically manage signing**.
2. Pick your `Team`. If your team is empty, click `Add an Account…` and sign
   in with your Apple ID first. Free Apple IDs appear as
   `Personal Team (<your name>)`.

If Xcode complains about an identifier already in use, change the Bundle ID to
something more unique.

## 4. Connect your iPhone

Wired:

1. Plug the iPhone into the Mac with a Lightning/USB-C cable.
2. Unlock the iPhone and tap "Trust" on the prompt.
3. Wait for Xcode to finish "Preparing device for development" (only on the
   first connection).

Wirelessly (after a first wired pairing):

1. Open Xcode → `Window` → `Devices and Simulators`.
2. Select your iPhone in the sidebar.
3. Tick `Connect via network`. From now on the device shows up in the device
   picker whenever it is on the same Wi-Fi.

## 5. Run on a real device

1. In the device picker at the top of the Xcode window, pick your iPhone.
2. Press ⌘R.
3. The first install on a free Apple Developer account fails on launch with
   "Untrusted Developer". Fix it on the phone:
   - `Settings` → `General` → `VPN & Device Management`
   - Tap your Apple ID under `DEVELOPER APP`
   - Tap `Trust`
   - Open Neon Tetris from the home screen.

> Free Apple IDs let you keep up to 3 sideloaded apps signed for 7 days at a
> time. After that you must re-run from Xcode to refresh. To bypass the
> 7-day limit, join the Apple Developer Program ($99/year) — see TESTFLIGHT.md.

## 6. Run on the iOS Simulator

1. Pick `iPhone 17 Air` (or any iPhone 15/16/17 model) in the device picker.
2. ⌘R. The Simulator launches.

Some hardware features behave slightly differently on the Simulator:

- CoreHaptics is silent (no taptic engine in the Simulator).
- AVAudioEngine outputs to the Mac speakers via the host audio device.
- Frame pacing is generally slower than on-device.

## 7. Archive for distribution

1. Pick `Any iOS Device (arm64)` in the device picker.
2. `Product` → `Archive`. Xcode builds a Release build and opens the Organizer.
3. In the Organizer pick the new archive and use `Distribute App`. Pick:
   - `TestFlight & App Store` to upload to App Store Connect (recommended,
     covered in TESTFLIGHT.md).
   - `Ad Hoc` to produce an `.ipa` for registered UDIDs only.
   - `Development` to produce a `.ipa` you can install on your own paired
     devices via Apple Configurator or Devices & Simulators.

## Frequent fixes

| Symptom | Fix |
|---------|-----|
| `Signing for "NeonTetris" requires a development team` | Pick a Team in `Signing & Capabilities`. |
| `An App ID with Identifier 'com.example.NeonTetris' is not available` | Change the Bundle Identifier to something unique. |
| Build fails with `Cannot find type 'PBXFileSystemSynchronizedRootGroup'` or "Unsupported objectVersion" | Update Xcode. The project needs Xcode 16+. |
| `xcrun: error: SDK "iphoneos" cannot be located` | Open Xcode at least once after install to accept the license. |
| Black screen, then crash on launch | Make sure the deployment target on the device matches `IPHONEOS_DEPLOYMENT_TARGET = 17.0`. Older OS will reject the binary. |
| Tests target won't link with `@testable import NeonTetris` | Ensure the `NeonTetris` Debug config still has `ENABLE_TESTABILITY = YES` (it does in this template). |

## Command-line build (optional)

```bash
xcodebuild \
  -project NeonTetris.xcodeproj \
  -scheme NeonTetris \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17 Air" \
  build
```

For an archive:

```bash
xcodebuild \
  -project NeonTetris.xcodeproj \
  -scheme NeonTetris \
  -configuration Release \
  -archivePath build/NeonTetris.xcarchive \
  -destination "generic/platform=iOS" \
  archive
```

You still need a valid signing identity / provisioning profile to actually
sign the archive.
