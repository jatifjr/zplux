#!/usr/bin/env zsh
# Note: sourced by init.zsh or bin/zplux after ZPLUX_HOME is set

typeset -g _zplux_root="${ZPLUX_HOME}"
typeset -g _zplux_comp_dir="${_zplux_root}/completions"
typeset -g _zplux_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zplux"
typeset -g _zplux_compdump="${_zplux_cache}/.zcompdump"
