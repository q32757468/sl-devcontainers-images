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

# Download an install script and prefix its GitHub Release download URLs with
# the supplied proxy URL. Runtime curl/wget calls are wrapped as well, so URLs
# obtained dynamically from an API or manifest are also proxied. Prints the
# path to a self-cleaning local launcher.
download_install_script_with_github_proxy() {
    local script_url="${1:?Usage: download_install_script_with_github_proxy <script-url> <proxy-url>}"
    local proxy_url="${2:?Usage: download_install_script_with_github_proxy <script-url> <proxy-url>}"
    local runtime_dir
    local downloaded_script
    local rewritten_script
    local escaped_proxy_url
    local downloader
    local downloader_path

    proxy_url="${proxy_url%/}/"
    runtime_dir="$(mktemp -d "${TMPDIR:-/tmp}/proxied-installer.XXXXXX")"
    downloaded_script="${runtime_dir}/install.sh.download"
    rewritten_script="${runtime_dir}/install.sh"
    install -d -m 0755 "${runtime_dir}/bin"
    : >"${runtime_dir}/.runtime"
    printf '%s\n' "${proxy_url}" >"${runtime_dir}/proxy-url"

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "${script_url}" -o "${downloaded_script}"; then
            rm -rf "${runtime_dir}"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -qO "${downloaded_script}" "${script_url}"; then
            rm -rf "${runtime_dir}"
            return 1
        fi
    else
        echo "Either curl or wget is required to download ${script_url}." >&2
        rm -rf "${runtime_dir}"
        return 1
    fi

    escaped_proxy_url="$(printf '%s' "${proxy_url}" | sed 's/[&|\\]/\\&/g')"
    if ! sed -E \
        "s|https://github\\.com/[[:alnum:]_.-]+/[[:alnum:]_.-]+/releases/download/|${escaped_proxy_url}&|g" \
        "${downloaded_script}" >"${rewritten_script}"; then
        rm -rf "${runtime_dir}"
        return 1
    fi

    rm -f "${downloaded_script}"
    chmod 0755 "${rewritten_script}"

    cat >"${runtime_dir}/bin/download-with-github-proxy" <<'EOF'
#!/usr/bin/env bash
set -e

wrapper_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
runtime_dir="$(dirname -- "${wrapper_dir}")"
downloader="${0##*/}"
proxy_url="$(<"${runtime_dir}/proxy-url")"
downloader_path="$(<"${runtime_dir}/${downloader}-path")"
rewritten_args=()

for argument in "$@"; do
    case "${argument}" in
        https://github.com/*/*/releases/download/*)
            argument="${proxy_url}${argument}"
            ;;
        --url=https://github.com/*/*/releases/download/*)
            argument="--url=${proxy_url}${argument#--url=}"
            ;;
    esac
    rewritten_args+=("${argument}")
done

exec "${downloader_path}" "${rewritten_args[@]}"
EOF
    chmod 0755 "${runtime_dir}/bin/download-with-github-proxy"

    for downloader in curl wget; do
        if downloader_path="$(command -v "${downloader}" 2>/dev/null)"; then
            printf '%s\n' "${downloader_path}" >"${runtime_dir}/${downloader}-path"
            ln -s download-with-github-proxy "${runtime_dir}/bin/${downloader}"
        fi
    done

    cat >"${runtime_dir}/run.sh" <<'EOF'
#!/bin/sh
set -e

runtime_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cleanup() {
    case "${runtime_dir##*/}" in
        proxied-installer.*)
            if [ -f "${runtime_dir}/.runtime" ]; then
                rm -rf -- "${runtime_dir}"
            fi
            ;;
    esac
}
trap cleanup EXIT HUP INT TERM

export PATH="${runtime_dir}/bin:${PATH}"
"${runtime_dir}/install.sh" "$@"
EOF
    chmod 0755 "${runtime_dir}/run.sh"

    if [[ -n "${_REMOTE_USER:-}" ]] && id "${_REMOTE_USER}" >/dev/null 2>&1; then
        chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${runtime_dir}"
    fi

    printf '%s\n' "${runtime_dir}/run.sh"
}
