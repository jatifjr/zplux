#!/usr/bin/env zsh
# Note: sourced by lib/core/dispatch.zsh on demand

_zplux_cmd_update_fail() {
  print -u2 "zplux update: $1"
  return 1
}

_zplux_require_repo_ready() {
  local repo_dir="$1"

  _zplux_require_git_repo "${repo_dir}" _zplux_cmd_update_fail || return 1
  if ! _zplux_git_quiet "${repo_dir}" diff --quiet || ! _zplux_git_quiet "${repo_dir}" diff --cached --quiet; then
    _zplux_cmd_update_fail "working tree must be clean"
    return 1
  fi
}

_zplux_ensure_remote() {
  local repo_dir="$1"
  local remote_name="$2"
  local remote_url="$3"

  _zplux_git_quiet "${repo_dir}" remote get-url "${remote_name}" && return 0
  _zplux_git_quiet "${repo_dir}" remote add "${remote_name}" "${remote_url}" || {
    _zplux_cmd_update_fail "failed to add remote '${remote_name}'"
    return 1
  }
}

_zplux_cmd_update() {
  local repo_dir="${_zplux_root}"
  local remote_name="zsh-completions"
  local remote_url="https://github.com/zsh-users/zsh-completions.git"
  local upstream_ref="${remote_name}/master"
  local upstream_tree=""
  local cached_upstream_tree=""
  local upstream_tree_stamp="${_zplux_cache}/.zcompdump.tree"
  local tmp_dir=""

  command -v git >/dev/null 2>&1 || {
    _zplux_cmd_update_fail "git is required"
    return 1
  }

  _zplux_require_repo_ready "${repo_dir}" || return 1
  _zplux_ensure_remote "${repo_dir}" "${remote_name}" "${remote_url}" || return 1
  mkdir -p "${_zplux_cache}" || {
    _zplux_cmd_update_fail "failed to create cache directory"
    return 1
  }

  _zplux_git_quiet "${repo_dir}" fetch "${remote_name}" master --quiet || {
    _zplux_cmd_update_fail "failed to fetch upstream"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" rev-parse --verify "${upstream_ref}" || {
    _zplux_cmd_update_fail "upstream ref '${upstream_ref}' is unavailable"
    return 1
  }

  upstream_tree="$(_zplux_git "${repo_dir}" rev-parse "${upstream_ref}:src" 2>/dev/null)" || {
    _zplux_cmd_update_fail "failed to resolve upstream src tree"
    return 1
  }
  if [[ -f "${upstream_tree_stamp}" ]]; then
    cached_upstream_tree="$(<"${upstream_tree_stamp}")"
    if [[ -n "${cached_upstream_tree}" && "${upstream_tree}" == "${cached_upstream_tree}" ]]; then
      print "zplux update: completions are up to date"
      return 0
    fi
  fi

  tmp_dir="$(mktemp -d "${_zplux_cache}/update.XXXXXX" 2>/dev/null)" || {
    _zplux_cmd_update_fail "failed to create temporary directory"
    return 1
  }
  _zplux_git "${repo_dir}" archive --format=tar "${upstream_ref}:src" 2>/dev/null | tar -xf - -C "${tmp_dir}" 2>/dev/null || {
    rm -rf "${tmp_dir}"
    _zplux_cmd_update_fail "failed to extract upstream completions"
    return 1
  }

  rm -rf "${_zplux_comp_dir}" || {
    rm -rf "${tmp_dir}"
    _zplux_cmd_update_fail "failed to replace local completions directory"
    return 1
  }
  mv "${tmp_dir}" "${_zplux_comp_dir}" || {
    rm -rf "${tmp_dir}"
    _zplux_cmd_update_fail "failed to install updated completions"
    return 1
  }
  printf "%s\n" "${upstream_tree}" > "${upstream_tree_stamp}" || {
    _zplux_cmd_update_fail "failed to write completions cache stamp"
    return 1
  }

  rm -f "${_zplux_compdump}" "${_zplux_compdump}.zwc"
  print "zplux update: completions are updated; restart shell"
}
