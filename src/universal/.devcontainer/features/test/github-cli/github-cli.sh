#!/usr/bin/env bash

source dev-container-features-test-lib

check "runtime-user" bash -c 'test "$(id -un)" = "ubuntu"'
check "gh" gh --version
check "gh-install-dir" test -x /usr/local/share/github-cli/bin/gh
check "gh-path" bash -c 'test "$(command -v gh)" = "/usr/local/share/github-cli/bin/gh"'
check "github-cli-post-create" test -x /usr/local/share/devcontainer-features/github-cli/post-create.sh
check "persist-vscode-git-token" bash -c '
    temp_dir="$(mktemp -d)"
    trap '\''rm -rf -- "${temp_dir}"'\'' EXIT
    printf '\''#!/usr/bin/env bash\nprintf "password=test-token\\n"\n'\'' > "${temp_dir}/git"
    printf '\''#!/usr/bin/env bash
test "$1" = "auth"
test "$2" = "login"
test "$3" = "--hostname"
test "$4" = "github.com"
test "$5" = "--with-token"
test "$(cat)" = "test-token"
'\'' > "${temp_dir}/gh"
    chmod +x "${temp_dir}/git"
    chmod +x "${temp_dir}/gh"
    PATH="${temp_dir}:${PATH}"
    source /usr/local/share/devcontainer-features/github-cli/post-create.sh
'
check "ignore-missing-git-token" bash -c '
    temp_dir="$(mktemp -d)"
    trap '\''rm -rf -- "${temp_dir}"'\'' EXIT
    printf '\''#!/usr/bin/env bash\ntest "${GIT_TERMINAL_PROMPT}" = "0"\nexit 1\n'\'' > "${temp_dir}/git"
    chmod +x "${temp_dir}/git"
    PATH="${temp_dir}:${PATH}"
    unset GH_TOKEN
    source /usr/local/share/devcontainer-features/github-cli/post-create.sh
    test -z "${GH_TOKEN:-}"
'
check "preserve-existing-gh-token" bash -c '
    GH_TOKEN="existing-token"
    export GH_TOKEN
    source /usr/local/share/devcontainer-features/github-cli/post-create.sh
    test "${GH_TOKEN}" = "existing-token"
'

reportResults
