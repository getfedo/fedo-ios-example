# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->


## Build & Test

Requires Xcode 26+. One shared scheme, `fedo-ios-example`, builds the app and runs the unit tests.

```bash
# Build: prints only warnings and errors; keep it at zero warnings
xcodebuild -scheme fedo-ios-example -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet build

# Unit tests: any installed iPhone simulator name works
xcodebuild -scheme fedo-ios-example -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO -quiet test
```

Tests use Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest. They decode an inline OpenRouter JSON fixture through `OpenRouter.decodeModels(from:)` and never touch the network.

CI: `.github/workflows/ci.yml` runs the same test command on macOS 26 / Xcode 26.5.

## Architecture Overview

ModelPulse is a SwiftUI demo of the Fedo iOS SDK (`FedoKit`, SPM, pinned to `0.3.0-beta.1`). It lists the newest AI models from the public OpenRouter API (`GET https://openrouter.ai/api/v1/models`, no key) and adds Fedo at natural moments. App sources live in `fedo-ios-example/`.

- `fedo_ios_exampleApp.swift`: `@main`; initializes Fedo once in `init()`; defines `Bundle.fedoAPIKey` (Info.plist `FedoAPIKey`, trimmed, `nil` when empty).
- `ContentView.swift`: root `TabView` with Models, Roadmap and Settings tabs, each in its own `NavigationStack`.
- `ModelsListView.swift`: fetch with loading/error/empty states and pull-to-refresh, search, provider filter menu, Fedo feedback sheet, `favorite_provider` user property; also `ModelRow`.
- `ModelDetailView.swift`: pricing, context length, release date, input modalities, copyable model ID.
- `SettingsView.swift`: Fedo setup status, demo sign-in/out that sets Fedo identity (persisted with `@AppStorage`), About links, app version.
- `AIModel.swift` + `StatusView.swift`: `AIModel` Decodable model and formatters, `OpenRouter.fetchModels()` / `decodeModels(from:)`; `StatusView` is the shared icon/title/message/actions view for empty, error and setup states.
- `Config/` (repo root): `Base.xcconfig` (app target base config, `FEDO_API_KEY`, optional `#include? "Secrets.xcconfig"`), `Secrets.example.xcconfig`, `Info.plist` (`FedoAPIKey = $(FEDO_API_KEY)`).
- `fedo-ios-exampleTests/AIModelTests.swift`: decoding, sort order and formatter tests.

Where each FedoKit API is used:

- `Fedo.initialize(apiKey:config:)`: `fedo_ios_exampleApp.init()`, only when a key exists (`.debug` logs in DEBUG, `.none` in release).
- `FeedbacksView()`: Roadmap tab in `ContentView`; without a key a "Fedo Not Configured" `StatusView` shows instead, because the uninitialized SDK renders blank.
- `.presentCreateFeedback(isPresented:)`: `ModelsListView`, from "Missing a model? Request it" (no results) and "Report a Problem" (load error); buttons hidden without a key.
- `Fedo.setUserProperty("favorite_provider", value:)`: `ModelsListView`, when a provider filter is picked.
- `Fedo.setUserID` / `Fedo.setUserDisplayName` / `Fedo.setUserEmail`: `SettingsView` sign-in (ID is `"demo-" + email`; real apps pass their backend user ID).
- `Fedo.logout()`: `SettingsView` sign-out.

## Conventions & Patterns

- **iOS 16.0 deployment target**: no iOS 17+ APIs (`ContentUnavailableView`, `@Observable`, `onChange(of:initial:)`, `navigationDestination(item:)`, ...) without an `#available` check. Use `@State`, `ObservableObject` and `.task`.
- **Swift 6 with default MainActor isolation** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, approachable concurrency): code is main-actor unless marked otherwise. Models and networking are `nonisolated` (+ `Sendable`); off-main work uses `@concurrent` (see `OpenRouter.fetchModels()`).
- **SwiftUI + Foundation only**: no dependencies beyond FedoKit.
- **Synchronized folders**: `fedo-ios-example/` and `fedo-ios-exampleTests/` are file-system synchronized groups, so new `.swift` files compile without a `project.pbxproj` edit. Keep non-source files (xcconfig, plist, fixtures) out of them unless you handle target membership.
- **Zero warnings**: the build command above must report no warnings.
- **Keep the example minimal and readable**: it is sample code for SDK integrators. Fewest files, no speculative abstractions, short comments only where a choice is not obvious.
- **API key**: `Config/Base.xcconfig` leaves `FEDO_API_KEY` empty; put a key in the gitignored `Config/Secrets.xcconfig` (copy `Config/Secrets.example.xcconfig`). Without a key the app still builds, runs and tests, and Fedo UI shows setup guidance. Never commit API keys. Read the key only through `Bundle.main.fedoAPIKey`.
- **`project.pbxproj`**: Xcode may reorder objects when it opens the project; commit order-only changes separately from real changes.
