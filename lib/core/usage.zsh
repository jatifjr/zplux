#!/usr/bin/env zsh
# Note: sourced by init.zsh or bin/zplux

_zplux_usage() {
  print -- "Usage: zplux <command>"
  print -- ""
  print -- "Commands:"
  print -- "  update    Sync vendored completions with upstream"
  print -- "  upgrade   Force-sync this repo to origin/main"
  print -- "  status    Show installation, cache, and repo state"
  print -- "  help      Show help for a command (e.g. zplux help update)"
}

_zplux_help() {
  local topic="${1:-}"
  case "${topic}" in
    update)
      print -- "zplux update — Sync vendored completions with upstream zsh-completions/master."
      ;;
    upgrade)
      print -- "zplux upgrade — Force-sync this repo to origin/main. Destructive: discards local changes and removes untracked files."
      ;;
    status)
      print -- "zplux status — Print zplux installation, cache, and repo state. No network."
      ;;
    "")
      _zplux_usage
      ;;
    *)
      _zplux_usage
      ;;
  esac
}
