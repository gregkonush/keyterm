# Repository Guidelines

## Project Structure & Module Organization
- `Sources/HostApp/`: container app used for setup and installation guidance.
- `Sources/KeyboardExtension/`: keyboard extension logic, layout, theming, and key behavior.
- `Tests/KeyboardExtensionTests/`: XCTest unit tests for keyboard logic (for example, theme palette behavior).
- `project.yml`: XcodeGen source of truth for targets, schemes, and build settings.
- `KeyTerm.xcodeproj`: generated Xcode project opened in Xcode.
- `docs/images/`: screenshots and documentation assets.

## Build, Test, and Development Commands
- `xcodegen generate`: regenerate `KeyTerm.xcodeproj` after editing `project.yml`.
- `open KeyTerm.xcodeproj`: open the project in Xcode for simulator/device iteration.
- `xcodebuild -project KeyTerm.xcodeproj -scheme KeyTerm -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`: CI-friendly build without signing.
- `xcodebuild -project KeyTerm.xcodeproj -scheme KeyTerm -destination 'platform=iOS Simulator,name=iPhone 15' test`: run unit tests from terminal.

## Coding Style & Naming Conventions
- Language: Swift 5, UIKit-based, 4-space indentation, no tabs.
- Follow Swift API naming: `UpperCamelCase` for types, `lowerCamelCase` for methods/properties, enum cases in `lowerCamelCase`.
- Prefer narrow visibility (`private`/`fileprivate`) and `final` for concrete classes unless subclassing is required.
- Keep keyboard key labels and terminal control text explicit and ASCII-safe where practical.

## Testing Guidelines
- Framework: XCTest (`Tests/KeyboardExtensionTests`).
- Test files end with `Tests.swift`; test methods start with `test...`.
- Add or update tests for behavior changes in key mapping, modifier handling, and visual theme logic.
- Keep tests deterministic and independent of external services or network state.

## Commit & Pull Request Guidelines
- Match existing history style: short, imperative commit subjects (for example, `Stabilize keyboard height to prevent switch-time layout jump`).
- Keep commits focused; avoid mixing refactors with behavior changes.
- PRs should include:
  - concise summary of user-visible behavior changes,
  - test evidence (commands run),
  - screenshots for UI/layout updates (`docs/images/` when appropriate),
  - linked issue/ticket when available.

## Configuration & Security Notes
- Local signing settings may differ by contributor; use unique bundle IDs and team values for personal builds.
- Do not commit secrets or provisioning artifacts.
- Keep extension privacy posture intact unless intentionally changing it (for example, `RequestsOpenAccess` in extension `Info.plist`).
