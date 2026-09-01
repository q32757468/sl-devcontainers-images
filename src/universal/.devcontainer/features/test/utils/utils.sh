#!/usr/bin/env bash

source dev-container-features-test-lib

check "utils-library" test -r /usr/local/share/devcontainer-features/utils/utils.sh
check "persistent-directory-linker" test -x /usr/local/share/devcontainer-features/utils/link-persistent-directory.sh
check "utils-functions" bash -c '
    source /usr/local/share/devcontainer-features/utils/utils.sh
    declare -F get_remote_user_home >/dev/null
    declare -F run_as_remote_user >/dev/null
    declare -F link_persistent_directory >/dev/null
    declare -F install_lifecycle_script >/dev/null
    declare -F download_install_script_with_github_proxy >/dev/null
'

check "persistent-directory-link-idempotency-and-migration" bash -c '
    set -e
    source /usr/local/share/devcontainer-features/utils/utils.sh

    native_root="${HOME}/.persistent-link-test"
    native_path="${native_root}/native"
    storage_path="${HOME}/.sl-cache/.persistent-link-test/native"
    trap '\''rm -rf -- "${native_root}" "${HOME}/.sl-cache/.persistent-link-test"'\'' EXIT

    rm -rf -- "${native_root}" "${HOME}/.sl-cache/.persistent-link-test"
    mkdir -p "${native_path}/nested" "${storage_path}/nested"
    printf '\''from-image\n'\'' >"${native_path}/native-only"
    printf '\''from-image\n'\'' >"${native_path}/nested/conflict"
    printf '\''from-volume\n'\'' >"${storage_path}/nested/conflict"
    printf '\''persistent\n'\'' >"${storage_path}/persistent-only"

    link_persistent_directory cache "${native_path}"

    test -L "${native_path}"
    test "$(readlink "${native_path}")" = "${storage_path}"
    grep -Fxq from-image "${storage_path}/native-only"
    grep -Fxq from-volume "${storage_path}/nested/conflict"
    grep -Fxq persistent "${storage_path}/persistent-only"

    link_persistent_directory cache "${native_path}"
    rm -rf -- "${storage_path}"
    link_persistent_directory cache "${native_path}"
    test -d "${native_path}"
'

check "persistent-directory-link-rejects-unsafe-paths" bash -c '
    set -e
    source /usr/local/share/devcontainer-features/utils/utils.sh

    for unsafe_path in \
        "${HOME}" \
        "${HOME}/." \
        "${HOME}/.sl-config" \
        "${HOME}/.sl-config/nested" \
        "${HOME}/.sl-cache" \
        "${HOME}/.sl-cache/nested"; do
        if link_persistent_directory cache "${unsafe_path}"; then
            echo "Unsafe persistent path was accepted: ${unsafe_path}" >&2
            exit 1
        fi
    done

    if /usr/local/share/devcontainer-features/utils/link-persistent-directory.sh cache .; then
        echo "The HOME-relative entrypoint accepted '.'." >&2
        exit 1
    fi
'

check "persistent-directory-link-preserves-source-on-copy-failure" bash -c '
    set -e
    source /usr/local/share/devcontainer-features/utils/utils.sh

    native_path="${HOME}/.persistent-link-copy-failure"
    storage_path="${HOME}/.sl-cache/.persistent-link-copy-failure"
    trap '\''rm -rf -- "${native_path}" "${storage_path}"'\'' EXIT
    mkdir -p "${native_path}"
    printf '\''must-survive\n'\'' >"${native_path}/data"

    _copy_missing_directory_entries() { return 1; }
    if link_persistent_directory cache "${native_path}"; then
        echo "Persistent link unexpectedly succeeded after a copy failure." >&2
        exit 1
    fi

    test ! -L "${native_path}"
    grep -Fxq must-survive "${native_path}/data"
'

check "persistent-directory-link-rejects-different-symlink" bash -c '
    set -e
    source /usr/local/share/devcontainer-features/utils/utils.sh

    native_path="${HOME}/.persistent-link-wrong-target"
    wrong_target="${HOME}/.persistent-link-other-target"
    storage_path="${HOME}/.sl-cache/.persistent-link-wrong-target"
    trap '\''rm -rf -- "${native_path}" "${wrong_target}" "${storage_path}"'\'' EXIT
    mkdir -p "${wrong_target}"
    ln -s "${wrong_target}" "${native_path}"

    if link_persistent_directory cache "${native_path}"; then
        echo "A different symlink target was overwritten." >&2
        exit 1
    fi

    test "$(readlink "${native_path}")" = "${wrong_target}"
'

check "github-release-proxy" bash -c '
    set -e
    test_dir="$(mktemp -d)"
    trap '\''rm -rf "${test_dir}"'\'' EXIT

    cat >"${test_dir}/source.sh" <<'\''EOF'\''
#!/usr/bin/env bash
set -e
static_url=https://github.com/example/tool/releases/download/v1.2.3/tool.tar.gz
homepage=https://github.com/example/tool
release_url="https://github.com/${TEST_OWNER}/${TEST_REPOSITORY}/releases/download/v2.0.0/tool.tar.gz"
curl -fsSL --retry 3 "${release_url}" -o "${TEST_CURL_OUTPUT}"
wget -qO "${TEST_WGET_OUTPUT}" "${release_url}"
curl -fsSL "https://example.com/ordinary-download" -o "${TEST_ORDINARY_OUTPUT}"
EOF

    cat >"${test_dir}/curl" <<'\''EOF'\''
#!/usr/bin/env bash
printf '\''%s\n'\'' "$*" >>"${TEST_CURL_LOG}"
output=""
source_url=""
while (($#)); do
    if [[ "$1" == "-o" ]]; then
        output="$2"
        shift
    elif [[ "$1" == "https://example.test/install.sh" ]]; then
        source_url="$1"
    fi
    shift
done
if [[ -n "${source_url}" ]]; then
    cp "${TEST_INSTALL_SCRIPT}" "${output}"
else
    : >"${output}"
fi
EOF
    chmod +x "${test_dir}/curl"

    cat >"${test_dir}/wget" <<'\''EOF'\''
#!/usr/bin/env bash
printf '\''%s\n'\'' "$*" >>"${TEST_WGET_LOG}"
while (($#)); do
    if [[ "$1" == "-qO" ]]; then
        : >"$2"
        exit
    fi
    shift
done
exit 1
EOF
    chmod +x "${test_dir}/wget"

    export TEST_INSTALL_SCRIPT="${test_dir}/source.sh"
    export TEST_CURL_LOG="${test_dir}/curl.log"
    export TEST_WGET_LOG="${test_dir}/wget.log"
    export TEST_CURL_OUTPUT="${test_dir}/curl-output"
    export TEST_WGET_OUTPUT="${test_dir}/wget-output"
    export TEST_ORDINARY_OUTPUT="${test_dir}/ordinary-output"
    export TEST_OWNER="example"
    export TEST_REPOSITORY="dynamic-tool"
    PATH="${test_dir}:${PATH}"
    source /usr/local/share/devcontainer-features/utils/utils.sh
    launcher="$(download_install_script_with_github_proxy \
        https://example.test/install.sh https://gh.hihsl.cn/)"

    test -x "${launcher}"
    runtime_dir="$(dirname "${launcher}")"
    grep -Fq \
        "https://gh.hihsl.cn/https://github.com/example/tool/releases/download/v1.2.3/tool.tar.gz" \
        "${runtime_dir}/install.sh"
    grep -Fxq "homepage=https://github.com/example/tool" "${runtime_dir}/install.sh"

    sh "${launcher}"

    grep -Fq -- \
        "-fsSL --retry 3 https://gh.hihsl.cn/https://github.com/example/dynamic-tool/releases/download/v2.0.0/tool.tar.gz -o ${TEST_CURL_OUTPUT}" \
        "${TEST_CURL_LOG}"
    grep -Fq -- \
        "-qO ${TEST_WGET_OUTPUT} https://gh.hihsl.cn/https://github.com/example/dynamic-tool/releases/download/v2.0.0/tool.tar.gz" \
        "${TEST_WGET_LOG}"
    grep -Fq -- \
        "-fsSL https://example.com/ordinary-download -o ${TEST_ORDINARY_OUTPUT}" \
        "${TEST_CURL_LOG}"
    test ! -e "${runtime_dir}"

    for proxy_argument in omitted empty; do
        : >"${TEST_CURL_LOG}"
        : >"${TEST_WGET_LOG}"

        if [[ "${proxy_argument}" == omitted ]]; then
            launcher="$(download_install_script_with_github_proxy \
                https://example.test/install.sh)"
        else
            launcher="$(download_install_script_with_github_proxy \
                https://example.test/install.sh "")"
        fi

        runtime_dir="$(dirname "${launcher}")"
        grep -Fq \
            "https://github.com/example/tool/releases/download/v1.2.3/tool.tar.gz" \
            "${runtime_dir}/install.sh"

        sh "${launcher}"

        grep -Fq -- \
            "-fsSL --retry 3 https://github.com/example/dynamic-tool/releases/download/v2.0.0/tool.tar.gz -o ${TEST_CURL_OUTPUT}" \
            "${TEST_CURL_LOG}"
        grep -Fq -- \
            "-qO ${TEST_WGET_OUTPUT} https://github.com/example/dynamic-tool/releases/download/v2.0.0/tool.tar.gz" \
            "${TEST_WGET_LOG}"
        grep -Fq -- \
            "-fsSL https://example.com/ordinary-download -o ${TEST_ORDINARY_OUTPUT}" \
            "${TEST_CURL_LOG}"
        test ! -e "${runtime_dir}"
    done
'

reportResults
