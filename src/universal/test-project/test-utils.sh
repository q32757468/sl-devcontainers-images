#!/bin/bash
SCRIPT_FOLDER="$(cd "$(dirname $0)" && pwd)"
USERNAME=${1:-hsl}

if [ -z $HOME ]; then
    HOME="/root"
fi

FAILED=()

echoStderr()
{
    echo "$@" 1>&2
}

check() {
    LABEL=$1
    shift
    echo -e "\n🧪 Testing $LABEL"
    if "$@"; then
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

check-version-ge() {
    LABEL=$1
    CURRENT_VERSION=$2
    REQUIRED_VERSION=$3
    shift
    echo -e "\n🧪 Testing $LABEL: '$CURRENT_VERSION' is >= '$REQUIRED_VERSION'"
    local GREATER_VERSION=$((echo ${CURRENT_VERSION}; echo ${REQUIRED_VERSION}) | sort -V | tail -1)
    if [ "${CURRENT_VERSION}" == "${GREATER_VERSION}" ]; then
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkOSPackages() {
    LABEL=$1
    shift
    echo -e "\n🧪 Testing $LABEL"
    if dpkg-query --show -f='${Package}: ${Version}\n' "$@"; then
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkMultiple() {
    PASSED=0
    LABEL="$1"
    echo -e "\n🧪 Testing $LABEL."
    shift; MINIMUMPASSED=$1
    shift; EXPRESSION="$1"
    while [ "$EXPRESSION" != "" ]; do
        if $EXPRESSION; then ((PASSED++)); fi
        shift; EXPRESSION=$1
    done
    if [ $PASSED -ge $MINIMUMPASSED ]; then
        echo "✅ Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkVersionCount() {
    LABEL=$1
    count=$2
    expectedCount=$3
    echo -e "\n🧪 Testing $LABEL"

    if [ "$count" == "$expectedCount" ]; then
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed. Got $count, expected $expectedCount."
        FAILED+=("$LABEL")
        return 1
    fi
}

reportResults() {
    if [ ${#FAILED[@]} -ne 0 ]; then
        echoStderr -e "\n💥  Failed tests: ${FAILED[@]}"
        exit 1
    else
        echo -e "\n💯  All passed!"
        exit 0
    fi
}
