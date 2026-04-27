#!/usr/bin/env zsh
# Note: sourced by lib/core/dispatch.zsh on demand

_zplux_cmd_upgrade_fail() {
  print -u2 "zplux upgrade: $1"
  return 1
}

_zplux_cmd_upgrade() {
  local repo_dir="${_zplux_root}"
  local remote_name="origin"
  local remote_ref="${remote_name}/main"
  local local_head=""
  local remote_head=""

  command -v git >/dev/null 2>&1 || {
    _zplux_cmd_upgrade_fail "git is required"
    return 1
  }
  _zplux_require_git_repo "${repo_dir}" _zplux_cmd_upgrade_fail || return 1
  _zplux_git_quiet "${repo_dir}" remote get-url "${remote_name}" || {
    _zplux_cmd_upgrade_fail "remote '${remote_name}' is required"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" fetch "${remote_name}" main --quiet || {
    _zplux_cmd_upgrade_fail "failed to fetch ${remote_ref}"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" rev-parse --verify "${remote_ref}" || {
    _zplux_cmd_upgrade_fail "remote ref '${remote_ref}' is unavailable"
    return 1
  }
  local_head="$(_zplux_git "${repo_dir}" rev-parse HEAD 2>/dev/null)" || {
    _zplux_cmd_upgrade_fail "failed to resolve local HEAD"
    return 1
  }
  remote_head="$(_zplux_git "${repo_dir}" rev-parse "${remote_ref}" 2>/dev/null)" || {
    _zplux_cmd_upgrade_fail "failed to resolve ${remote_ref}"
    return 1
  }
  if [[ "${local_head}" == "${remote_head}" ]]; then
    print "zplux upgrade: zplux is up to date"
    return 0
  fi

  _zplux_git_quiet "${repo_dir}" checkout -B main "${remote_ref}" || {
    _zplux_cmd_upgrade_fail "failed to checkout local main from ${remote_ref}"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" reset --hard "${remote_ref}" || {
    _zplux_cmd_upgrade_fail "failed to hard reset to ${remote_ref}"
    return 1
  }
  _zplux_git_quiet "${repo_dir}" clean -fd || {
    _zplux_cmd_upgrade_fail "failed to clean untracked files"
    return 1
  }

  print "zplux upgrade: zplux upgraded to ${remote_ref}; restart shell"
}
