#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS_COUNT=0

pass() {
  printf "PASS: %s\n" "$1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  printf "FAIL: %s\n" "$1" >&2
  exit 1
}

if zsh -c "unset ZPLUX_HOME; source \"$ROOT_DIR/init.zsh\"" >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "init.zsh should fail without ZPLUX_HOME"
fi
if ! grep -q "ZPLUX_HOME is required" /tmp/zplux_verify_err; then
  fail "missing expected ZPLUX_HOME error message"
fi
pass "init.zsh rejects missing ZPLUX_HOME"

if ! zsh -c "export ZPLUX_HOME=\"$ROOT_DIR\"; source \"$ROOT_DIR/init.zsh\"" >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "init.zsh should load with valid ZPLUX_HOME"
fi
pass "init.zsh loads with ZPLUX_HOME"

if ! zsh -c "export ZPLUX_HOME=\"$ROOT_DIR\"; source \"$ROOT_DIR/init.zsh\"; whence -w zplux | grep -q 'function'" >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "expected zplux function"
fi
pass "public zplux command is exposed"

if ! "$ROOT_DIR/bin/zplux" >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "bin/zplux without args should exit 0"
fi
if ! grep -q "Usage: zplux" /tmp/zplux_verify_out; then
  fail "bin/zplux without args should print usage"
fi
pass "bin/zplux prints usage with no args"

if ! "$ROOT_DIR/bin/zplux" help update >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "bin/zplux help update should exit 0"
fi
if ! grep -q "Sync vendored completions" /tmp/zplux_verify_out; then
  fail "bin/zplux help update should mention sync"
fi
pass "bin/zplux help update shows update help"

if ! "$ROOT_DIR/bin/zplux" update --help >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "bin/zplux update --help should exit 0"
fi
if ! grep -q "Sync vendored completions" /tmp/zplux_verify_out; then
  fail "bin/zplux update --help should mention sync"
fi
pass "bin/zplux update --help shows update help"

TEMP_HOME="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_HOME"
}
trap cleanup EXIT
mkdir -p "$TEMP_HOME/lib/core" "$TEMP_HOME/lib/helpers" "$TEMP_HOME/lib/commands"
cp "$ROOT_DIR/init.zsh" "$TEMP_HOME/init.zsh"
cp "$ROOT_DIR/lib/core/env.zsh" "$TEMP_HOME/lib/core/env.zsh"
cp "$ROOT_DIR/lib/core/usage.zsh" "$TEMP_HOME/lib/core/usage.zsh"
cp "$ROOT_DIR/lib/core/dispatch.zsh" "$TEMP_HOME/lib/core/dispatch.zsh"
cp "$ROOT_DIR/lib/core/runtime.zsh" "$TEMP_HOME/lib/core/runtime.zsh"
cp "$ROOT_DIR/lib/helpers/git.zsh" "$TEMP_HOME/lib/helpers/git.zsh"
cp "$ROOT_DIR/lib/commands/update.zsh" "$TEMP_HOME/lib/commands/update.zsh"
cp "$ROOT_DIR/lib/commands/upgrade.zsh" "$TEMP_HOME/lib/commands/upgrade.zsh"
cp "$ROOT_DIR/lib/commands/status.zsh" "$TEMP_HOME/lib/commands/status.zsh"

if ! zsh -c "export ZPLUX_HOME=\"$TEMP_HOME\"; source \"$TEMP_HOME/init.zsh\"" >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "init.zsh should still load when completions directory is missing"
fi
if ! grep -q "please run 'zplux update' and restart your shell" /tmp/zplux_verify_err; then
  fail "missing expected completions warning"
fi
pass "init.zsh warns when completions directory is missing"

if ! ZPLUX_HOME="$TEMP_HOME" "$ROOT_DIR/bin/zplux" status >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "bin/zplux status with temp ZPLUX_HOME should exit 0"
fi
if ! grep -q "ZPLUX_HOME:" /tmp/zplux_verify_out; then
  fail "bin/zplux status should print ZPLUX_HOME"
fi
pass "bin/zplux status prints ZPLUX_HOME"

printf "All checks passed (%d).\n" "$PASS_COUNT"
