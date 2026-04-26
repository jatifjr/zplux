# zplux

Minimal zsh completion bootstrap with explicit, manual upstream sync.

## What this project does

- Adds vendored `completions/` to `fpath`
- Initializes completion with `compinit`
- Uses an XDG cache-backed `.zcompdump`
- Compiles `.zcompdump.zwc` when stale
- Provides a single public update command: `zplux-update`

Startup stays local-only. No network sync runs during shell init.

## Project structure

- `init.zsh` - thin entrypoint sourced from `.zshrc`
- `lib/runtime.zsh` - startup-only runtime (`fpath`, `compinit`, cache build)
- `lib/update.zsh` - git subtree update workflow and guards
- `bin/zplux-update` - standalone updater entrypoint
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
2. Loads `lib/runtime.zsh` and `lib/update.zsh`
3. Exposes `zplux-update`
4. Runs `zplux_init`

Cache location:

```zsh
${XDG_CACHE_HOME:-$HOME/.cache}/zplux/.zcompdump
```

Compiled cache:

```zsh
${XDG_CACHE_HOME:-$HOME/.cache}/zplux/.zcompdump.zwc
```

## Updating completions

After sourcing `init.zsh`, run:

```zsh
zplux-update
```

Standalone updater (works even if shell function is not loaded):

```zsh
"$ZPLUX_HOME/bin/zplux-update"
```

Update flow:

1. Ensures `git` exists and repo is in a valid/clean state
2. Fetches upstream `zsh-completions/master`
3. Bootstraps `completions/` with subtree **add** when missing from git history
4. Otherwise compares upstream `src` tree to local `completions/`
5. Runs subtree pull only when there is a change
6. Invalidates local compdump cache files

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
- `zplux-update` command exposure

If your repo does not track `completions/` yet (for example, clean clone with `completions/` excluded), running `zplux-update` will initialize it automatically.
