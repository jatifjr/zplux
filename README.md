# zplux

Minimal zsh completion bootstrap with explicit, manual upstream sync.

## What this project does

- Adds vendored `completions/` to `fpath`
- Initializes completion with `compinit`
- Uses an XDG cache-backed `.zcompdump`
- Compiles `.zcompdump.zwc` when stale
- Provides public maintenance commands: `zplux update`, `zplux upgrade`, and `zplux status`

Startup stays local-only. No network sync runs during shell init. Subcommand implementations under `lib/commands/` are loaded only when you run that subcommand (lazy load).

## Project structure

- `init.zsh` - shell bootstrap sourced from `.zshrc`
- `lib/core/env.zsh` - path globals (`_zplux_root`, completions dir, cache, compdump)
- `lib/core/usage.zsh` - `_zplux_usage` and `_zplux_help` (per-command help)
- `lib/core/dispatch.zsh` - `_zplux_dispatch` (routes subcommands, lazy-sources command files)
- `lib/core/runtime.zsh` - `zplux_init` (`fpath`, `compinit`, cache compile)
- `lib/helpers/git.zsh` - shared git helpers
- `lib/commands/update.zsh` - completions update workflow
- `lib/commands/upgrade.zsh` - self-upgrade workflow
- `lib/commands/status.zsh` - local diagnostics (no network)
- `bin/zplux` - standalone CLI (same dispatch as the shell function)
- `completions/` - mirrored upstream completion files
- `tests/verify.sh` - lightweight behavior checks

## Installation

Recommended location:

```zsh
${XDG_DATA_HOME:-$HOME/.local/share}/zplux
```

In your `.zshrc`:

```zsh
export ZPLUX_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zplux"
source "$ZPLUX_HOME/init.zsh"
```

`init.zsh` requires `ZPLUX_HOME` to be set.

## Runtime behavior

When sourced, `init.zsh`:

1. Validates `ZPLUX_HOME`
2. Loads core modules (`env`, `usage`, `dispatch`, `runtime`) from `lib/core/`
3. Exposes `zplux` with `update`, `upgrade`, `status`, and `help` entry points
4. Runs `zplux_init`

`update`, `upgrade`, and `status` are not sourced until you invoke them (via `zplux <cmd>` or `bin/zplux <cmd>`).

Cache location:

```zsh
${XDG_CACHE_HOME:-$HOME/.cache}/zplux/.zcompdump
```

Compiled cache:

```zsh
${XDG_CACHE_HOME:-$HOME/.cache}/zplux/.zcompdump.zwc
```

## Commands

Overview:

```zsh
zplux              # or: zplux help
zplux help update  # per-command description
zplux update --help # same as help update
```

### Updating completions

After sourcing `init.zsh`, run:

```zsh
zplux update
```

Standalone:

```zsh
"$ZPLUX_HOME/bin/zplux" update
```

Update flow:

1. Ensures `git` exists and repo is in a valid/clean state
2. Fetches upstream `zsh-completions/master`
3. Resolves upstream `src` tree and compares with tracked local `completions` tree when available
4. Uses a local cache stamp for upstream tree idempotency when `completions/` is not git-tracked
5. Exports upstream `src` into a temporary directory and atomically replaces local `completions/`
6. Cleans temporary artifacts and invalidates local compdump cache files

If `completions/` is missing during startup, zplux prints a warning and suggests running `zplux update`.

### Upgrading zplux itself

```zsh
zplux upgrade
```

Standalone:

```zsh
"$ZPLUX_HOME/bin/zplux" upgrade
```

`zplux upgrade` behavior:

1. Requires `origin` remote and fetches `origin/main`
2. Force-checkouts local `main` from `origin/main`
3. Hard-resets to `origin/main`
4. Cleans untracked files

Warning: this command is intentionally destructive for local modifications. It discards local tracked changes and removes untracked files.

### Status

Prints `ZPLUX_HOME`, completions directory summary, cache/compdump paths, optional git short HEAD (clean/dirty), and the upstream completions tree stamp when present. No network access.

```zsh
zplux status
"$ZPLUX_HOME/bin/zplux" status
```

## Upstream mirror policy

`completions/` is intended to mirror:

- `https://github.com/zsh-users/zsh-completions` (`src/`)

Do not mix local custom completions into `completions/`. Keep custom completions in a separate directory.

## Verification

Run quick checks:

```bash
tests/verify.sh
```

Current checks cover:

- expected failure when `ZPLUX_HOME` is missing
- successful load with `ZPLUX_HOME` set
- `zplux` shell function exposure
- `bin/zplux` usage with no arguments
- `bin/zplux help update` and `bin/zplux update --help`
- `bin/zplux status` with a temporary `ZPLUX_HOME`
- startup warning when `completions/` is missing

If your repo does not track `completions/` yet (for example, clean clone with `completions/` excluded), running `zplux update` will initialize it automatically.

Versioning for this project is not exposed via zplux; use `git` in your checkout as usual.
