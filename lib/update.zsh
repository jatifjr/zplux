#!/usr/bin/env zsh
# Note: sourced by init.zsh, bin/zplux-update, or bin/zplux-upgrade

_zplux_update_fail() {
  print -u2 "zplux-update: $1"
  return 1
}

_zplux_upgrade_fail() {
  print -u2 "zplux-upgrade: $1"
  return 1
}

_zplux_git() {
  local repo_dir="$1"
  shift
  git -C "${repo_dir}" "$@"
}

_zplux_git_quiet() {
  local repo_dir="$1"
  shift
  _zplux_git "${repo_dir}" "$@" >/dev/null 2>&1
}

_zplux_require_git_repo() {
  local repo_dir="$1"
  local fail_func="$2"

  _zplux_git_quiet "${repo_dir}" rev-parse --is-inside-work-tree || {
    "${fail_func}" "'${repo_dir}' is not a git repository"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" rev-parse --verify HEAD || {
    "${fail_func}" "repository has no commits yet"
    return 1
  }
}

_zplux_require_repo_ready() {
  local repo_dir="$1"

  _zplux_require_git_repo "${repo_dir}" _zplux_update_fail || return 1
  if ! _zplux_git_quiet "${repo_dir}" diff --quiet || ! _zplux_git_quiet "${repo_dir}" diff --cached --quiet; then
    _zplux_update_fail "working tree must be clean"
    return 1
  fi
}

_zplux_ensure_remote() {
  local repo_dir="$1"
  local remote_name="$2"
  local remote_url="$3"

  _zplux_git_quiet "${repo_dir}" remote get-url "${remote_name}" && return 0
  _zplux_git_quiet "${repo_dir}" remote add "${remote_name}" "${remote_url}" || {
    _zplux_update_fail "failed to add remote '${remote_name}'"
    return 1
  }
}

_zplux_has_committed_completions_tree() {
  local repo_dir="$1"
  _zplux_git_quiet "${repo_dir}" rev-parse --verify HEAD:completions
}

_zplux_upgrade_run() {
  local repo_dir="${_zplux_root}"
  local remote_name="origin"
  local remote_ref="${remote_name}/main"
  local local_head=""
  local remote_head=""

  command -v git >/dev/null 2>&1 || {
    _zplux_upgrade_fail "git is required"
    return 1
  }
  _zplux_require_git_repo "${repo_dir}" _zplux_upgrade_fail || return 1
  _zplux_git_quiet "${repo_dir}" remote get-url "${remote_name}" || {
    _zplux_upgrade_fail "remote '${remote_name}' is required"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" fetch "${remote_name}" main --quiet || {
    _zplux_upgrade_fail "failed to fetch ${remote_ref}"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" rev-parse --verify "${remote_ref}" || {
    _zplux_upgrade_fail "remote ref '${remote_ref}' is unavailable"
    return 1
  }
  local_head="$(_zplux_git "${repo_dir}" rev-parse HEAD 2>/dev/null)" || {
    _zplux_upgrade_fail "failed to resolve local HEAD"
    return 1
  }
  remote_head="$(_zplux_git "${repo_dir}" rev-parse "${remote_ref}" 2>/dev/null)" || {
    _zplux_upgrade_fail "failed to resolve ${remote_ref}"
    return 1
  }
  if [[ "${local_head}" == "${remote_head}" ]]; then
    print "zplux-upgrade: zplux up to date"
    return 0
  fi

  print "zplux-upgrade: force syncing to ${remote_ref} (local changes will be discarded)"
  _zplux_git_quiet "${repo_dir}" checkout -B main "${remote_ref}" || {
    _zplux_upgrade_fail "failed to checkout local main from ${remote_ref}"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" reset --hard "${remote_ref}" || {
    _zplux_upgrade_fail "failed to hard reset to ${remote_ref}"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" clean -fd || {
    _zplux_upgrade_fail "failed to clean untracked files"
    return 1
  }

  print "zplux-upgrade: zplux upgraded to ${remote_ref}; restart shell"
}

_zplux_update_run() {
  local repo_dir="${_zplux_root}"
  local remote_name="zsh-completions"
  local remote_url="https://github.com/zsh-users/zsh-completions.git"
  local upstream_ref="${remote_name}/master"
  local upstream_tree=""
  local local_tree=""
  local tmp_dir=""
  local had_completions_dir=0

  command -v git >/dev/null 2>&1 || {
    _zplux_update_fail "git is required"
    return 1
  }

  _zplux_require_repo_ready "${repo_dir}" || return 1
  _zplux_ensure_remote "${repo_dir}" "${remote_name}" "${remote_url}" || return 1
  mkdir -p "${_zplux_cache}" || {
    _zplux_update_fail "failed to create cache directory"
    return 1
  }

  _zplux_git_quiet "${repo_dir}" fetch "${remote_name}" master --quiet || {
    _zplux_update_fail "failed to fetch upstream"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" rev-parse --verify "${upstream_ref}" || {
    _zplux_update_fail "upstream ref '${upstream_ref}' is unavailable"
    return 1
  }

  upstream_tree="$(_zplux_git "${repo_dir}" rev-parse "${upstream_ref}:src" 2>/dev/null)" || {
    _zplux_update_fail "failed to resolve upstream src tree"
    return 1
  }
  if _zplux_has_committed_completions_tree "${repo_dir}"; then
    local_tree="$(_zplux_git "${repo_dir}" rev-parse HEAD:completions 2>/dev/null)" || local_tree=""
  else
    local_tree=""
  fi

  if [[ -n "${local_tree}" && "${upstream_tree}" == "${local_tree}" ]]; then
    print "zplux-update: completions up to date"
    return 0
  fi

  tmp_dir="$(mktemp -d "${_zplux_cache}/update.XXXXXX" 2>/dev/null)" || {
    _zplux_update_fail "failed to create temporary directory"
    return 1
  }
  _zplux_git "${repo_dir}" archive --format=tar "${upstream_ref}:src" 2>/dev/null | tar -xf - -C "${tmp_dir}" 2>/dev/null || {
    rm -rf "${tmp_dir}"
    _zplux_update_fail "failed to extract upstream completions"
    return 1
  }

  [[ -d "${_zplux_comp_dir}" ]] && had_completions_dir=1
  rm -rf "${_zplux_comp_dir}" || {
    rm -rf "${tmp_dir}"
    _zplux_update_fail "failed to replace local completions directory"
    return 1
  }
  mv "${tmp_dir}" "${_zplux_comp_dir}" || {
    rm -rf "${tmp_dir}"
    _zplux_update_fail "failed to install updated completions"
    return 1
  }

  rm -f "${_zplux_compdump}" "${_zplux_compdump}.zwc"
  if (( had_completions_dir )); then
    print "zplux-update: completions updated; restart shell"
  else
    print "zplux-update: completions bootstrapped; restart shell"
  fi
}
