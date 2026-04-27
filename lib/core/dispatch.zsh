#!/usr/bin/env zsh
# Note: sourced by init.zsh or bin/zplux

_zplux_dispatch() {
  local cmd="${1:-}"
  (( $# > 0 )) && shift

  case "${cmd}" in
    ""|help|-h|--help)
      _zplux_help "${1:-}"
      return 0
      ;;
    update|upgrade|status)
      if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
        _zplux_help "${cmd}"
        return 0
      fi
      source "${_zplux_root}/lib/helpers/git.zsh"
      source "${_zplux_root}/lib/commands/${cmd}.zsh"
      "_zplux_cmd_${cmd}" "$@"
      ;;
    *)
      _zplux_usage
      ;;
  esac
}
