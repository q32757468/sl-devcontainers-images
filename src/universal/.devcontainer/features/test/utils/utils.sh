#!/usr/bin/env bash

source dev-container-features-test-lib

check "utils-library" test -r /usr/local/share/devcontainer-features/utils/utils.sh
check "utils-functions" bash -c '
    source /usr/local/share/devcontainer-features/utils/utils.sh
    declare -F get_remote_user_home >/dev/null
    declare -F run_as_remote_user >/dev/null
    declare -F install_lifecycle_script >/dev/null
'

reportResults
