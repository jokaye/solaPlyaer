# Sola Player

Sola Player is an iOS 17+ SwiftUI audio player. Product and interaction decisions live in `docs/`.

## Local setup

1. Install Xcode 16 or newer and select it with `xcode-select`.
2. Install XcodeGen if needed: `brew install xcodegen`.
3. Run `xcodegen generate` from the repository root.
4. Open `SolaPlayer.xcodeproj` and run the `SolaPlayer` scheme.

The build phase embeds the current Git commit SHA. Check it from **About** in the app before comparing a manually installed build with source history.
