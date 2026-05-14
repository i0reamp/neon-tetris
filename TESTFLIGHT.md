# TestFlight: distributing Neon Tetris to your iPhone

TestFlight is Apple's official beta-distribution system. It is the only
above-board way to get a build onto a tester's iPhone without that tester
plugging it into your Mac. Anything else (signing tricks, third-party stores,
enterprise certificates for non-employees) violates the developer agreement
and is out of scope for this project.

This guide assumes you finished BUILD.md and the app builds cleanly to a
device.

## 0. What you need

- Paid **Apple Developer Program** membership ($99 USD/year).
  TestFlight does not work with a free Apple ID. Free accounts can only run
  the app from Xcode directly on devices you own.
- Access to **App Store Connect** with the same Apple ID.
- An **App Record** for Neon Tetris in App Store Connect.

## 1. Reserve the Bundle ID in your account

1. Go to <https://developer.apple.com/account/resources/identifiers/list>.
2. Click `+` → `App IDs` → `App`.
3. Description: `Neon Tetris`. Bundle ID: `Explicit`, matching what you set
   in Xcode (e.g. `com.<you>.neontetris`).
4. Capabilities: none required for the default project (no push, no iCloud,
   no Game Center). Click `Continue` → `Register`.

## 2. Create the app record in App Store Connect

1. Go to <https://appstoreconnect.apple.com/apps>.
2. `+` → `New App`.
3. Platform: iOS. Name: `Neon Tetris`. Primary language: English (or whatever
   you prefer). Bundle ID: pick the one you just registered. SKU: anything
   unique to you (e.g. `neon-tetris-001`). User Access: Full Access.
4. Click `Create`.

> You do not have to fill in any of the App Store metadata yet to use
> TestFlight. The required fields for TestFlight itself are minimal.

## 3. Bump the build / version

In Xcode, open the project, select the `NeonTetris` target → `General`:

- `Version` is your marketing version (e.g. `1.0.0`).
- `Build` is an integer that must be **strictly increasing** every time you
  upload. After your first upload, bump it (e.g. to `2`) before the next.

## 4. Archive a Release build

1. Pick `Any iOS Device (arm64)` in the device picker.
2. `Product` → `Archive`. Xcode builds Release and opens the Organizer when
   it is done.

## 5. Upload to App Store Connect

In the Organizer:

1. Select the archive you just made.
2. Click `Distribute App`.
3. Pick `App Store Connect` → `Upload`.
4. Distribution options: leave the defaults (Symbols on, manage signing
   automatically).
5. `Automatically manage signing` is fine — Xcode requests / generates a
   distribution certificate and a provisioning profile in your account.
6. Confirm the summary screen, click `Upload`. The upload usually takes
   ~1 minute on a fast connection.

Xcode will report `Upload Successful`. The build then enters Apple's
processing queue. Processing typically takes 5–30 minutes; you receive a
"Build has finished processing" email when it is ready.

## 6. Export Compliance (one-time per build)

In App Store Connect → your app → `TestFlight`:

1. Click the new build (it shows `Missing Compliance`).
2. Answer the encryption questionnaire. Neon Tetris does not use custom
   cryptography — it only uses HTTPS through the OS, which is exempt. The
   answer is `No`.
3. Save.

You can avoid this prompt on every build by adding the following to the app
target's Info plist (or as `INFOPLIST_KEY_*` in build settings):

```
ITSAppUsesNonExemptEncryption = NO
```

## 7. Pick the kind of testing

### A. Internal testing (fastest, no review)

Internal testers are members of your App Store Connect team. Up to 100 of
them across up to 100 devices each. They get builds within minutes of
upload.

1. App Store Connect → your app → `TestFlight` → `Internal Testing`.
2. Add yourself / teammates by their Apple IDs. They must be invited to your
   App Store Connect team first (`Users and Access` page).
3. Add the build to the group.
4. Internal testers receive a TestFlight invite email immediately.

### B. External testing (covers anyone)

Up to 10,000 external testers per app. First build requires a quick **Beta
App Review** (usually < 24 h). Subsequent builds in the same major version
do not require re-review.

1. App Store Connect → your app → `TestFlight` → `External Testing`.
2. Create a group, e.g. `Friends`.
3. Add testers by Apple ID **or** generate a `Public Link`. The link can
   accept up to 10,000 sign-ups.
4. Add the build → submit for Beta App Review → wait for approval.
5. Testers receive an invite or use the public link.

> Beta App Review is lighter than App Store review. Common reasons to be
> rejected: crash on launch, missing privacy policy URL if you collect data,
> not honest about TestFlight Notes / What to Test. Neon Tetris collects no
> user data, so leave those fields blank or empty.

## 8. Install on the tester's iPhone

The tester does this on their iPhone:

1. From the App Store, install **TestFlight** (free, by Apple). If they
   already have it, skip.
2. Open the email invite **on the iPhone** and tap `View in TestFlight`.
   Or tap the public link.
3. TestFlight opens. Tap `Accept`, then `Install`.
4. The Neon Tetris icon appears on the home screen. Tap to launch.

## 9. Updating a tester

Upload a new build with a higher Build number. Add it to the group. Internal
testers see it immediately. External testers see it once Beta App Review
clears (often just minutes for follow-up builds).

You can also send a What to Test note: `App Store Connect → TestFlight →
Build → What to Test`.

## 10. Inviting the original requester

The requester of this project should be invited as an internal tester:

1. App Store Connect → `Users and Access` → `+` → enter their Apple ID
   email — `nektokot@gmail.com` — and pick role `Developer` or `Marketing`.
2. They accept the invite by email.
3. Now in `TestFlight → Internal Testing`, you can add them to the build.
4. They install TestFlight on their iPhone and tap the invite email.

If you'd rather not add them to your team, use external testing instead and
send them the public TestFlight link.

## 11. What if you do not want to use TestFlight?

Officially supported alternatives, all covered briefly:

- **Direct install from Xcode**: requires you to physically have or pair to
  the device, but does not require an Apple Developer Program membership.
  Builds expire after 7 days on free accounts.
- **Ad Hoc**: in the Organizer, pick `Distribute App` → `Ad Hoc`. You can
  only install on UDIDs registered with your team. Generates a signed
  `.ipa` you can install via Apple Configurator 2 or via Devices &
  Simulators in Xcode. Requires paid membership.
- **Apple Business Manager / Apple School Manager Custom Apps**: for
  organisations distributing to staff/students; out of scope here.

The following are **not** acceptable and not supported by this project:
jailbreak-only stores, enterprise certificates for non-employees, "shady
sideload" services. They violate the Apple Developer Program Agreement.

## Reference

- Apple's official TestFlight docs: <https://developer.apple.com/testflight/>
- TestFlight tester help: <https://testflight.apple.com>
- Beta App Review guidelines: <https://developer.apple.com/app-store/review/guidelines/#testflight>
