# Support

## Documentation

- [README](README.md) — install, usage, and on-disk layout
- [CONTRIBUTING.md](CONTRIBUTING.md) — development setup
- [AGENTS.md](AGENTS.md) — architecture for coding agents

## Getting help

1. Check the [README](README.md) and existing [issues](https://github.com/andresousadotpt/macban/issues).
2. Search [closed issues](https://github.com/andresousadotpt/macban/issues?q=is%3Aissue+is%3Aclosed).
3. Open a [new issue](https://github.com/andresousadotpt/macban/issues/new/choose) with the appropriate template.

For bugs, include your macOS version, install method, and whether you used `make run` or the packaged app (`make app`).

## Common topics

| Topic | Notes |
| ----- | ----- |
| **Where is my data?** | Projects live in folders you choose. Recent projects are tracked at `~/Library/Application Support/Macban/recent.json`. |
| **Syncing** | Put project folders in Syncthing, iCloud Drive, Dropbox, etc. Each column is a separate JSON file for cleaner merges. |
| **External edits** | The file watcher reloads boards when synced files change on disk. Same-column concurrent edits resolve last-write-wins. |
| **Gatekeeper / "app is damaged"** | Expected for Homebrew and GitHub Release builds (ad-hoc signed). Right-click → Open, or build from source with `make app`. |
| **Tests fail to run** | `make test` needs full Xcode installed, not Command Line Tools alone. |

## Security issues

Do not open public issues for security vulnerabilities. See [SECURITY.md](SECURITY.md).

## Feature requests

We welcome ideas. Please use the feature request template and describe the problem you are trying to solve.

## No official support SLA

This is an open-source project maintained in spare time. Issues and pull requests are handled as capacity allows.
