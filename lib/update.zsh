#!/usr/bin/env zsh
# Note: sourced by init.zsh or bin/zplux-update

_zplux_update_fail() {
  print -u2 "zplux-update: $1"
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

_zplux_require_repo_ready() {
  local repo_dir="$1"

  _zplux_git_quiet "${repo_dir}" rev-parse --is-inside-work-tree || {
    _zplux_update_fail "'${repo_dir}' is not a git repository"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" rev-parse --verify HEAD || {
    _zplux_update_fail "repository has no commits yet"
    return 1
  }
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

_zplux_update_run() {
  local repo_dir="${_zplux_root}"
  local remote_name="zsh-completions"
  local remote_url="https://github.com/zsh-users/zsh-completions.git"
  local upstream_ref="${remote_name}/master"
  local upstream_tree=""
  local local_tree=""
  local split_commit=""
  local subtree_action="pull"

  command -v git >/dev/null 2>&1 || {
    _zplux_update_fail "git is required"
    return 1
  }

  _zplux_require_repo_ready "${repo_dir}" || return 1
  _zplux_ensure_remote "${repo_dir}" "${remote_name}" "${remote_url}" || return 1

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
    subtree_action="add"
    local_tree=""
  fi

  if [[ -n "${local_tree}" && "${upstream_tree}" == "${local_tree}" ]]; then
    print "zplux-update: completions already up to date"
    return 0
  fi

  split_commit="$(printf "zsh-completions src split\n" | _zplux_git "${repo_dir}" commit-tree "${upstream_tree}" 2>/dev/null)" || {
    _zplux_update_fail "failed to prepare subtree split commit"
    return 1
  }
  if [[ "${subtree_action}" == "add" ]]; then
    _zplux_git_quiet "${repo_dir}" subtree add --prefix=completions . "${split_commit}" --squash || {
      _zplux_update_fail "subtree add failed"
      return 1
    }
  else
    _zplux_git_quiet "${repo_dir}" subtree pull --prefix=completions . "${split_commit}" --squash || {
      _zplux_update_fail "subtree pull failed"
      return 1
    }
  fi

  rm -f "${_zplux_compdump}" "${_zplux_compdump}.zwc"
  if [[ "${subtree_action}" == "add" ]]; then
    print "zplux-update: bootstrapped completions and invalidated compdump cache"
  else
    print "zplux-update: synced completions and invalidated compdump cache"
  fi
}
