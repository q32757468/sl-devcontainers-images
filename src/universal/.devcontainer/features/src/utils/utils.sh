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

# Store a directory in one of the shared config/cache roots and keep the
# application's absolute path as a symlink to it.
link_persistent_directory() {
    local storage_type="${1:?Usage: link_persistent_directory <config|cache> <absolute-path>}"
    local native_path="${2:?Usage: link_persistent_directory <config|cache> <absolute-path>}"
    local remote_user_home
    local storage_root
    local relative_path
    local storage_path
    local native_parent

    case "${storage_type}" in
        config | cache) ;;
        *)
            echo "Unsupported persistent storage type: ${storage_type}." >&2
            return 1
            ;;
    esac

    case "${native_path}" in
        /*) ;;
        *)
            echo "Persistent path must be absolute: ${native_path}." >&2
            return 1
            ;;
    esac
    case "/${native_path#/}/" in
        */../*)
            echo "Persistent path must not contain '..': ${native_path}." >&2
            return 1
            ;;
    esac

    remote_user_home="$(get_remote_user_home)"
    storage_root="${remote_user_home}/.sl-${storage_type}"
    if [[ "${native_path}" == "${remote_user_home}/"* ]]; then
        relative_path="${native_path#"${remote_user_home}/"}"
    else
        relative_path="${native_path#/}"
    fi
    storage_path="${storage_root}/${relative_path}"
    native_parent="$(dirname "${native_path}")"

    if [[ -e "${native_path}" || -L "${native_path}" ]]; then
        echo "Persistent path already exists: ${native_path}." >&2
        return 1
    fi

    install -d -m 0755 -o "${_REMOTE_USER}" -g "${_REMOTE_USER}" \
        "${storage_root}" \
        "$(dirname "${storage_path}")" \
        "${storage_path}"
    if [[ ! -d "${native_parent}" ]]; then
        install -d -m 0755 -o "${_REMOTE_USER}" -g "${_REMOTE_USER}" "${native_parent}"
    fi
    ln -s "${storage_path}" "${native_path}"
    chown -h "${_REMOTE_USER}:${_REMOTE_USER}" "${native_path}"
}

# Install a Feature's lifecycle script (post-start.sh, post-create.sh, ...)
# at the stable path used by its metadata.
# By default, <lifecycle-name>.sh is resolved next to the calling install.sh.
install_lifecycle_script() {
    local feature_id="${1:?Usage: install_lifecycle_script <feature-id> [lifecycle-name] [script]}"
    local lifecycle_name="${2:-post-start}"
    local source_script="${3:-}"

    if [[ -z "${lifecycle_name}" ]]; then
        lifecycle_name="post-start"
    fi

    if [[ -z "${source_script}" ]]; then
        local caller_dir
        caller_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[1]}")" && pwd)"
        source_script="${caller_dir}/${lifecycle_name}.sh"
    fi

    local runtime_dir="/usr/local/share/devcontainer-features/${feature_id}"
    install -d -m 0755 "${runtime_dir}"
    install -m 0755 "${source_script}" "${runtime_dir}/${lifecycle_name}.sh"
}
