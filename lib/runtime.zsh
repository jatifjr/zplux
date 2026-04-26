#!/usr/bin/env zsh
# Note: sourced by init.zsh

zplux_build() {
  local source_file="${_zplux_compdump}"
  local compiled_file="${source_file}.zwc"

  [[ -f "${source_file}" ]] || return 0
  [[ -f "${compiled_file}" && "${source_file}" -ot "${compiled_file}" ]] && return 0

  zcompile "${source_file}" >/dev/null 2>&1 || return 0
}

zplux_init() {
  typeset -gaU fpath
  fpath=("${_zplux_comp_dir}" "${fpath[@]}")

  mkdir -p "${_zplux_cache}"
  autoload -Uz compinit
  compinit -i -d "${_zplux_compdump}"
  zplux_build
}
