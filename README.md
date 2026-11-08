# cli-butler

> An agent skill that gives any AI coding agent the ability to manage local CLI tools: inventory, install, upgrade, uninstall, reference-chain tracing, and capability enumeration.

## Why

Agents are great at installing tools and terrible at cleaning up after themselves. cli-butler makes provenance a first-class concept: every CLI belongs to exactly one **channel** (brew / npm / pipx / uv / cargo / gem / apt / manual), and the channel decides how it is installed, upgraded, and — critically — uninstalled. No more `rm`-ing brew-owned binaries or leaving launchd services half-disabled.

## Status

🚧 Skeleton. Requirements and design are done; implementation in progress.

- [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) — requirements & roadmap
- [docs/provenance.md](docs/provenance.md) — channel model
- [docs/design.md](docs/design.md) — architecture

## Install (once published)

```
npx skills add <repo>
```

## Usage

```
bin/list.sh                 # inventory all CLIs
bin/refchain.sh docker      # where does this come from, what references it
bin/cap.sh git              # what can this CLI do
```

## License

MIT
