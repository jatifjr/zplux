#!/usr/bin/env zsh
# Note: shared git helpers for zplux maintenance commands

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
