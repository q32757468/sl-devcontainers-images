#!/usr/bin/env bash

get_remote_user_home() {
    local remote_user="${_REMOTE_USER:-codespace}"
    local remote_user_home
    remote_user_home="$(getent passwd "${remote_user}" | cut -d: -f6)"

    if [[ -z "${remote_user_home}" ]]; then
        echo "Remote user '${remote_user}' does not exist or has no home directory." >&2
        return 1
    fi

    printf '%s\n' "${remote_user_home}"
}

# Run a command as the user that development tools connect as.
run_as_remote_user() {
    local remote_user="${_REMOTE_USER:-codespace}"
    local remote_user_home
    remote_user_home="$(get_remote_user_home)"

    runuser -u "${remote_user}" -- env \
        HOME="${remote_user_home}" \
        PATH="${PATH}" \
        "$@"
}

# Install a Feature's post-start.sh at the stable path used by its metadata.
# By default, post-start.sh is resolved next to the calling install.sh.
install_post_start_script() {
    local feature_id="${1:?Usage: install_post_start_script <feature-id> [script]}"
    local source_script="${2:-}"

    if [[ -z "${source_script}" ]]; then
        local caller_dir
        caller_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[1]}")" && pwd)"
        source_script="${caller_dir}/post-start.sh"
    fi

    local runtime_dir="/usr/local/share/devcontainer-features/${feature_id}"
    install -d -m 0755 "${runtime_dir}"
    install -m 0755 "${source_script}" "${runtime_dir}/post-start.sh"
}
