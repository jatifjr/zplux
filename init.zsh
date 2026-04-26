#!/usr/bin/env zsh
# Note: This file is zsh runtime code sourced from .zshrc.

if [[ -n "${_zplux_loaded:-}" ]]; then
  return 0
fi
typeset -g _zplux_loaded=1

if [[ -z "${ZPLUX_HOME:-}" ]]; then
  print -u2 "zplux: ZPLUX_HOME is required; set it in your .zshrc before sourcing init.zsh"
  return 1
fi

typeset -g _zplux_root="${ZPLUX_HOME}"
typeset -g _zplux_comp_dir="${_zplux_root}/completions"
typeset -g _zplux_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zplux"
typeset -g _zplux_compdump="${_zplux_cache}/.zcompdump"

source "${_zplux_root}/lib/runtime.zsh"
source "${_zplux_root}/lib/update.zsh"

# Public command surface uses kebab-case consistently.
eval 'zplux-update() { _zplux_update_run "$@"; }'

zplux_init
