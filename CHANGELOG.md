# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Each release notes the FedoKit version it targets.

## [Unreleased]

## [0.3.0] - 2026-09-15

First release of ModelPulse. Targets FedoKit `0.3.0-beta.1`.

### Added

- FedoKit `0.3.0-beta.1` Swift package dependency ([getfedo/fedo-ios](https://github.com/getfedo/fedo-ios)).
- Latest Models tab listing the newest AI models from the public OpenRouter API, newest first, with pull to refresh and loading, empty and error states.
- Search by model name or ID, and a provider filter menu with a model count per provider.
- Model detail screen with pricing per 1M tokens, context length, release date, input modalities, a copyable model ID and the description.
- Fedo initialization at app launch with `Fedo.initialize(apiKey:config:)`, with debug logging in Debug builds.
- API key setup through the gitignored `Config/Secrets.xcconfig` (template: `Config/Secrets.example.xcconfig`). The app builds, runs and tests without a key.
- Roadmap tab hosting the Fedo feedback board (`FeedbacksView`), with setup guidance when no API key is configured.
- Contextual feedback with `.presentCreateFeedback(isPresented:)`: "Missing a model? Request it" when nothing matches the search or filter, and "Report a Problem" when models fail to load. Both appear only when an API key is configured.
- `favorite_provider` Fedo user property, set when you pick a provider in the filter menu.
- Settings tab with a demo sign-in and sign-out (`Fedo.setUserID`, `Fedo.setUserDisplayName`, `Fedo.setUserEmail`, `Fedo.logout()`) and the Fedo SDK status.
- Unit tests (Swift Testing) for model decoding and formatters, using an inline fixture and no network.
- Shared `fedo-ios-example` scheme, so clean clones and CI can build and run the tests.
- GitHub Actions CI that builds and tests on macOS 26 with Xcode 26.5 and needs no secrets.
- README with screenshots and a map of where Fedo is used, contributing guide, MIT license, Contributor Covenant 2.1, security policy, issue forms, pull request template and Dependabot configuration.

### Changed

- The project targets iOS 16 and the Swift 6 language mode to match FedoKit's requirements.
- FedoKit is pinned to the exact version `0.3.0-beta.1` instead of tracking a branch.
- The app's home screen name is ModelPulse.
- The app version (shown in Settings) is 0.3.0, matching this release.

### Fixed

- A failed pull to refresh no longer fails silently: a "Couldn't refresh" row appears above the loaded models until the next successful load.
- The error state's buttons stack vertically when they don't fit side by side at large Dynamic Type sizes.
- Empty and error states scroll instead of truncating their text at large Dynamic Type sizes.

[Unreleased]: https://github.com/getfedo/fedo-ios-example/compare/0.3.0...HEAD
[0.3.0]: https://github.com/getfedo/fedo-ios-example/releases/tag/0.3.0
