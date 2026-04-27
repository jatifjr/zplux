#!/usr/bin/env zsh
# Note: This file is zsh runtime code sourced from .zshrc.

[[ -n "${_zplux_loaded:-}" ]] && return 0
typeset -g _zplux_loaded=1

if [[ -z "${ZPLUX_HOME:-}" ]]; then
  print -u2 "zplux: ZPLUX_HOME is required; set it in your .zshrc before sourcing init.zsh"
  return 1
fi

source "${ZPLUX_HOME}/lib/core/env.zsh"
source "${ZPLUX_HOME}/lib/core/usage.zsh"
source "${ZPLUX_HOME}/lib/core/dispatch.zsh"
source "${ZPLUX_HOME}/lib/core/runtime.zsh"

zplux() { _zplux_dispatch "$@"; }

zplux_init
