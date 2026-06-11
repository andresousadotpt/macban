# macban

A clean, modern, **local-first kanban** app for macOS. Each project is a plain folder
you create wherever you like, so it syncs effortlessly with Syncthing, iCloud Drive,
Dropbox, or anything else that syncs files. There is no account, no server, and no
network access.

## Features

- **Native SwiftUI** — menus, keyboard shortcuts, materials, drag-and-drop, light/dark mode, and the system accent color
- **Folder-based projects** — open or create a project anywhere on disk; default board includes Backlog plus To Do / In Progress / Done
- **Sync-friendly storage** — human-readable JSON partitioned per column; moving a card rewrites at most two small files
- **Crash-safe writes** — atomic file I/O and a file watcher that reloads changes made by sync tools

## On-disk layout

A project is any folder containing a `config.json`:

```
MyProject/
├── config.json                 # project metadata + board registry
└── boards/
    └── main/
        ├── board.json          # column definitions (incl. backlog)
        └── columns/
            ├── backlog.json
            ├── todo.json
            ├── in-progress.json
            └── done.json
```

Each `columns/{id}.json` is an ordered array of cards. The `order` field mirrors the
array index and is renumbered on every save, so the files stay tidy and diff cleanly.

Put a project folder inside any synced location and open it on another Mac — your cards
are there. Because each column is its own file, concurrent edits on different columns
merge naturally; edits to the same column resolve last-write-wins.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16+ (or the Swift 6 toolchain) to build from source

## Install

### Build from source (recommended)

```bash
git clone https://github.com/andresousadotpt/macban.git
cd macban
make app
open dist/macban.app
```

### Homebrew

```bash
brew tap andresousadotpt/tap
brew install --cask macban
```

### GitHub Release

Download `macban-{version}.zip` from [Releases](https://github.com/andresousadotpt/macban/releases), unzip, and open the app.

If macOS blocks launch the first time, right-click the app → **Open**, or use System Settings → Privacy & Security → **Open Anyway**.

## Usage

1. Launch macban and create a new project or open an existing project folder.
2. Add cards to the backlog or any column; drag cards between columns to update status.
3. Double-click a card to edit title, description, and labels.
4. Use **File → New Project…** (`⇧⌘N`) or **Open Project…** (`⌘O`) to switch projects.

Keyboard shortcuts are available from the File menu when a project is open.

## Development

```bash
make build    # debug build
make run      # build and launch via swift run
make test     # unit tests (requires full Xcode)
make app      # release .app in ./dist/
make clean    # remove build artifacts
```

If `swift test` reports `no such module 'Testing'`, point Swift at the full Xcode toolchain:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
make test
```

### Project layout

| Target | Purpose |
| ------ | ------- |
| **MacbanCore** | Models, storage, file watcher — no UI imports |
| **Macban** | SwiftUI shell, view models, drag-and-drop |

AI agents should read [AGENTS.md](AGENTS.md) for architecture and conventions.

## Releasing

Version lives in `packaging/Info.plist` (`CFBundleShortVersionString`). Push to `main` and GitHub Actions will build, publish a release zip, and update the Homebrew cask.

```bash
make bump-version BUMP=minor   # or BUMP=major
git add packaging/Info.plist && git commit -m "chore: bump version to X.Y.Z"
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

| Document | Purpose |
| -------- | ------- |
| [AGENTS.md](AGENTS.md) | Architecture and agent conventions |
| [SUPPORT.md](SUPPORT.md) | Help and FAQs |
| [SECURITY.md](SECURITY.md) | Report vulnerabilities privately |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

## License

MIT — see [LICENSE](LICENSE).
