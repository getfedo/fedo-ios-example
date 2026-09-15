# Contributing

Thanks for helping improve ModelPulse, the example app for the [FedoKit](https://github.com/getfedo/fedo-ios) iOS SDK. This app is documentation: people read it to learn how to integrate Fedo, so changes should keep it small and easy to follow.

By participating you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Prerequisites

- Xcode 26 or later (CI uses Xcode 26.5)
- Nothing else. FedoKit is resolved by Xcode through Swift Package Manager, and the deployment target is iOS 16.

## Setup

1. Clone the repository:

   ```sh
   git clone https://github.com/getfedo/fedo-ios-example.git
   cd fedo-ios-example
   ```

2. Optional: add a Fedo API key. The app builds, runs and tests without one; the Fedo-powered screens then explain how to set it up.

   ```sh
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```

   Set `FEDO_API_KEY` in `Config/Secrets.xcconfig`. The file is gitignored.

3. Open `fedo-ios-example.xcodeproj`, select the `fedo-ios-example` scheme and an iOS simulator, then run.

## Build and test

In Xcode, press Cmd+U. From the command line, run the same command CI runs:

```sh
xcodebuild test \
  -scheme fedo-ios-example \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

Pick any simulator installed on your machine for `name=`. CI additionally pins the Xcode version and caches Swift packages; see [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

## Project layout

| Path | Contents |
| --- | --- |
| `fedo-ios-example/fedo_ios_exampleApp.swift` | App entry point; initializes Fedo when an API key is configured |
| `fedo-ios-example/ContentView.swift` | Root tab view: Models, Roadmap (Fedo feedback board), Settings |
| `fedo-ios-example/AIModel.swift` | OpenRouter model type, formatters and `OpenRouter.fetchModels()` |
| `fedo-ios-example/ModelsListView.swift` | Models list with loading and error states, search and provider filter |
| `fedo-ios-example/ModelDetailView.swift` | Model detail screen |
| `fedo-ios-example/StatusView.swift` | Shared empty and error state view |
| `fedo-ios-example/SettingsView.swift` | Demo sign-in and sign-out (Fedo user identity) and Fedo setup status |
| `fedo-ios-exampleTests/` | Swift Testing unit tests for model decoding and formatters |
| `Config/Base.xcconfig` | App build settings; optionally includes `Secrets.xcconfig` |
| `Config/Secrets.example.xcconfig` | Template for the gitignored `Config/Secrets.xcconfig` |
| `Config/Info.plist` | Exposes `FEDO_API_KEY` to the app as `FedoAPIKey` |

`fedo-ios-example/` is a file-system synchronized group: new Swift files in it are added to the app target automatically.

## Guidelines

- Use SwiftUI and Foundation only. Do not add third-party dependencies beyond FedoKit.
- Keep the example minimal and readable. Prefer the obvious solution over abstractions; comment only where the reason is not clear from the code.
- Stay compatible with iOS 16. Wrap newer APIs in `#available`.
- Build with zero warnings.
- Add or update tests when you change logic (decoding, formatting, filtering).

## Workflow

1. Create a branch from `main`.
2. Make your change, build, and run the tests.
3. Add an entry under `## [Unreleased]` in [`CHANGELOG.md`](CHANGELOG.md).
4. Open a pull request against `main` and fill in the template. CI must pass.

Never commit `Config/Secrets.xcconfig` or any API key, and never paste keys in issues, pull requests or logs.

## Issue tracking

Maintainers plan work with [beads](https://github.com/gastownhall/beads) (`bd`); its data lives in `.beads/`. You do not need it: external contributors can use [GitHub issues](https://github.com/getfedo/fedo-ios-example/issues).

## Where to report

- Bugs and ideas for this example app: [GitHub issues](https://github.com/getfedo/fedo-ios-example/issues) in this repository.
- Bugs in the FedoKit SDK itself: [getfedo/fedo-ios issues](https://github.com/getfedo/fedo-ios/issues).
- Security vulnerabilities: privately, as described in [SECURITY.md](SECURITY.md).
- Conduct concerns: see the [Code of Conduct](CODE_OF_CONDUCT.md).
