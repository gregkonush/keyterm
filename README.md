# KeyTerm

Terminal-focused custom iOS keyboard with `Esc`, `Ctrl`, `Tab`, arrow keys, and ASCII-friendly layout for browser-based terminal sessions.

## Project layout

- `KeyTerm` (host app): setup screen and keyboard install instructions
- `KeyTermKeyboard` (keyboard extension): custom terminal key layout

## Requirements

- macOS with Xcode 16+
- iOS 16+ deployment target
- `xcodegen` (used to generate and update the `.xcodeproj`)

Install `xcodegen`:

```bash
brew install xcodegen
```

## Generate and open

```bash
xcodegen generate
open KeyTerm.xcodeproj
```

## Build (simulator)

```bash
xcodebuild \
  -project KeyTerm.xcodeproj \
  -scheme KeyTerm \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Enable on iPhone

1. Build and run the `KeyTerm` app on your iPhone.
2. On iPhone: `Settings -> General -> Keyboard -> Keyboards -> Add New Keyboard...`
3. Select `KeyTerm Keyboard`.
4. In your browser terminal input, tap the globe key and switch to `KeyTerm Keyboard`.

## Notes

- Arrow keys send ANSI escape sequences (`ESC [ A/B/C/D`).
- `Ctrl` is sticky for one keypress and emits ASCII control bytes (for example `Ctrl+C`).
- If you need clipboard/network access from the extension, set `RequestsOpenAccess` to `true` in `Sources/KeyboardExtension/Info.plist`.

