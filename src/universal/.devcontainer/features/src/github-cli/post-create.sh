#!/usr/bin/env bash

_load_gh_token() {
  [ -n "${GH_TOKEN:-}" ] && return 0

  local token

  token="$(
    printf 'protocol=https\nhost=github.com\n\n' |
      GIT_TERMINAL_PROMPT=0 git credential fill 2>/dev/null |
      sed -n 's/^password=//p'
  )" || return 0

  [ -n "$token" ] && export GH_TOKEN="$token"

  unset token
}

_load_gh_token
unset -f _load_gh_token
