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

if ! zsh -c "export ZPLUX_HOME=\"$ROOT_DIR\"; source \"$ROOT_DIR/init.zsh\"; whence -w zplux-update | grep -q 'function'; whence -w zplux-upgrade | grep -q 'function'" >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "expected zplux-update and zplux-upgrade functions"
fi
pass "public update and upgrade commands are exposed"

TEMP_HOME="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_HOME"
}
trap cleanup EXIT
mkdir -p "$TEMP_HOME/lib"
cp "$ROOT_DIR/init.zsh" "$TEMP_HOME/init.zsh"
cp "$ROOT_DIR/lib/runtime.zsh" "$TEMP_HOME/lib/runtime.zsh"
cp "$ROOT_DIR/lib/update.zsh" "$TEMP_HOME/lib/update.zsh"

if ! zsh -c "export ZPLUX_HOME=\"$TEMP_HOME\"; source \"$TEMP_HOME/init.zsh\"" >/tmp/zplux_verify_out 2>/tmp/zplux_verify_err; then
  fail "init.zsh should still load when completions directory is missing"
fi
if ! grep -q "please run zplux-update and restart your shell" /tmp/zplux_verify_err; then
  fail "missing expected completions warning"
fi
pass "init.zsh warns when completions directory is missing"

printf "All checks passed (%d).\n" "$PASS_COUNT"
