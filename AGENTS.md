# AGENTS.md

Instructions for AI coding agents working on **macban**.

## Project overview

- **What this is:** A native macOS kanban app with local-first JSON project folders.
- **Platform:** macOS 14 (Sonoma) or later. Swift Package Manager project; no Xcode project file.
- **License:** MIT
- **Repo:** https://github.com/andresousadotpt/macban

## App identity (`packaging/app.env`)

```bash
APP_BUNDLE_NAME=macban
APP_EXECUTABLE=Macban
APP_PACKAGE=Macban
APP_CORE=MacbanCore
APP_DISPLAY_NAME=macban
APP_BUNDLE_ID=com.macban.app
APP_SUPPORT_DIR=Macban
GITHUB_OWNER=andresousadotpt
GITHUB_REPO=macban
CASK_NAME=macban
HOMEBREW_TAP=andresousadotpt/homebrew-tap
```

**Do not rename** `Makefile`, `packaging/build-app.sh`, `packaging/bump-version.sh`, or workflow files — they read from `app.env`.

## Architecture

Two Swift targets with strict separation of concerns:

| Target | Role | Depends on |
|--------|------|------------|
| **MacbanCore** | Models, project layout, storage, file watcher | Foundation |
| **Macban** | SwiftUI app shell, view models, drag-and-drop | MacbanCore |

```
Sources/
├── MacbanCore/
│   ├── Models/         # Board, Card, Column, ProjectConfig
│   ├── Services/       # ProjectStore, ProjectLayout, FileWatcher, RecentProjects
│   └── Utilities/      # AtomicWrite, JSONCoding
└── Macban/
    ├── MacbanApp.swift
    ├── ViewModels/     # AppViewModel, BoardViewModel
    ├── Views/          # Board, columns, cards, welcome, settings
    ├── DragDrop/       # Drag session and column drop targets
    └── Support/        # Debouncer and other UI helpers
```

### On-disk layout

A project is any folder containing `config.json`:

```
MyProject/
├── config.json
└── boards/
    └── main/
        ├── board.json
        └── columns/
            ├── backlog.json
            ├── todo.json
            ├── in-progress.json
            └── done.json
```

Each `columns/{id}.json` is an ordered array of cards. Moving a card rewrites at most two column files.

### Key design choices

- **View models** use `@MainActor @Observable` (Observation framework).
- **Persistence** uses an `actor` (`ProjectStore`) for thread-safe disk I/O off the main thread.
- **Recent projects** live at `~/Library/Application Support/Macban/recent.json`.
- **Sync-friendly:** per-column JSON files, atomic writes, and a file watcher reload external changes.
- **Version source of truth:** `packaging/Info.plist` (`CFBundleShortVersionString`).

## Build and run

```bash
make build    # swift build (debug)
make run      # build + swift run
make test     # swift test — requires full Xcode
make app      # release .app bundle in ./dist/
make clean    # remove .build/ and dist/
```

### Important runtime gotchas

1. **`swift run` vs packaged app:** Both work; use `make app` for release QA and distribution.
2. **Tests:** Swift Testing requires the full Xcode toolchain, not Command Line Tools alone.
3. **Version source of truth:** `packaging/Info.plist` (`CFBundleShortVersionString`).

## Testing

Tests live in `Tests/MacbanCoreTests/` and target **MacbanCore only**. UI is not unit-tested.

```bash
make test
swift test --filter MacbanCoreTests
```

## Code style and conventions

- **Swift tools version:** 6.0 (`Package.swift`).
- **Minimum deployment:** macOS 14.
- Prefer `Sendable`, `Codable`, and `Equatable` on models in MacbanCore.
- Use `public` on MacbanCore types consumed by the app target.
- Do not add UI imports (`SwiftUI`, `AppKit`) to MacbanCore.
- New **models** → `Sources/MacbanCore/Models/`
- New **file I/O or storage** → `Sources/MacbanCore/Services/` or `Utilities/`
- New **screens** → `Sources/Macban/Views/`
- New **UI helpers** → `Sources/Macban/Support/` or `DragDrop/`

## Packaging and release

See README.md. Releases are ad-hoc signed via CI on push to `main`.

## Git and PR guidelines

- **Do not commit** unless explicitly asked.
- **Do not push** unless explicitly asked.
- Run `make build` before finishing; run `make test` when MacbanCore logic changed.
- For UI changes, verify with `make app` → `open dist/macban.app`.

## Security and privacy

- All project data stays **local** in folders the user chooses.
- No network access; no accounts or servers.
- Do not commit secrets or tokens.

## Human-facing docs

- **README.md** — install, usage, on-disk layout (update when user-visible behavior changes).
- **AGENTS.md** (this file) — agent-oriented architecture and conventions.
