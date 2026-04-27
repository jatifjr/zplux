#!/usr/bin/env zsh
# Note: sourced by lib/core/dispatch.zsh on demand

_zplux_cmd_status() {
  emulate -L zsh
  setopt localoptions nullglob extendedglob

  local -a zf uf
  local stamp="${_zplux_cache}/.zcompdump.tree"

  print -- "ZPLUX_HOME: ${_zplux_root}"

  if [[ -d "${_zplux_comp_dir}" ]]; then
    zf=("${_zplux_comp_dir}"/*.zsh(N))
    uf=("${_zplux_comp_dir}"/_*(N))
    print -- "completions: ${_zplux_comp_dir} (${#zf} *.zsh, ${#uf} _*)"
  else
    print -- "completions: missing (${_zplux_comp_dir})"
  fi

  print -- "cache: ${_zplux_cache}"
  print -- "compdump: ${_zplux_compdump}"
  if [[ -f "${_zplux_compdump}.zwc" ]]; then
    print -- "compdump.zwc: present"
  else
    print -- "compdump.zwc: absent"
  fi

  if _zplux_git_quiet "${_zplux_root}" rev-parse --is-inside-work-tree; then
    local sha=""
    sha="$(_zplux_git "${_zplux_root}" rev-parse --short HEAD 2>/dev/null)" || sha="?"
    if _zplux_git_quiet "${_zplux_root}" diff --quiet && _zplux_git_quiet "${_zplux_root}" diff --cached --quiet; then
      print -- "git: ${sha} (clean)"
    else
      print -- "git: ${sha} (dirty)"
    fi
  else
    print -- "git: not a repository"
  fi

  if [[ -f "${stamp}" ]]; then
    print -- "upstream tree stamp: $(<"${stamp}")"
  fi
}
