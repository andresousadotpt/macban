# Contributing

Thank you for your interest in contributing. macban is a macOS kanban app built with Swift Package Manager.

## Before you start

- Read the [README](README.md) for install and usage.
- Browse [open issues](https://github.com/andresousadotpt/macban/issues) and [pull requests](https://github.com/andresousadotpt/macban/pulls) to avoid duplicate work.
- For larger changes, open an issue first to discuss the approach.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode Command Line Tools (`xcode-select --install`)
- Full **Xcode** (not Command Line Tools alone) to run `make test`

## Getting started

```bash
git clone https://github.com/andresousadotpt/macban.git
cd macban
make build
make run
make test
make app      # release .app in ./dist/ — use for manual QA
```

## Project layout

| Target | Purpose |
| ------ | ------- |
| **MacbanCore** | Models, persistence, file watcher — no UI imports |
| **Macban** | SwiftUI views, view models, drag-and-drop |

- New models → `Sources/MacbanCore/Models/`
- File I/O and storage → `Sources/MacbanCore/Services/` or `Utilities/`
- UI screens → `Sources/Macban/Views/`
- UI helpers → `Sources/Macban/Support/` or `DragDrop/`

AI coding agents should read [AGENTS.md](AGENTS.md) for deeper conventions.

## How to contribute

### Reporting bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include:

- macOS version
- How you installed (build from source, Homebrew, GitHub Release)
- Steps to reproduce and expected vs actual behavior
- Whether you used `make run` or the packaged `.app`

### Suggesting features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md). Describe the problem, your proposed solution, and any alternatives you considered.

### Pull requests

1. Fork the repo and create a branch from `main`.
2. Make focused changes — one logical change per PR when possible.
3. Run `make build` before opening the PR.
4. Run `make test` when you change **MacbanCore** logic.
5. For UI changes, note manual QA steps (`make app` → open `dist/macban.app`).
6. Open a PR against `main` and fill out the [pull request template](.github/pull_request_template.md).

### Commit messages

Use conventional prefixes when they fit:

- `feat:` — new user-facing behavior
- `fix:` — bug fix
- `docs:` — documentation only
- `chore:` — tooling, CI, version bumps
- `test:` — tests only

## Code guidelines

- **MacbanCore** must not import SwiftUI or AppKit.
- Match existing naming, structure, and patterns in the file you are editing.
- Avoid drive-by refactors unrelated to your change.
- Do not commit `.build/`, `dist/`, `.DS_Store`, or release artifacts.

### Testing

Tests live in `Tests/MacbanCoreTests/` and target **MacbanCore** only.

```bash
make test
```

UI behavior is validated manually via `make app`.

## Releases

Maintainers handle releases through CI on push to `main`. See [README — Releasing](README.md#releasing). Contributors do not need to bump versions unless asked.

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

## Questions

See [SUPPORT.md](SUPPORT.md).
