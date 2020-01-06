#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
ROOT_DIR=$(pwd)
popd > /dev/null

PUSH=false
BUILD=false

function usage () {
    echo "$0: $1" >&2
    echo
    echo "Usage: $0 [--build] [--push] <directory e.g. lts-14>"
    echo "See README.md for more information."
    echo
    return 1
}

function parseCmd () {
    STACK_RESOLVER_ARG=
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --build)
                BUILD=true
                shift
                ;;
            --push)
                PUSH=true
                shift
                ;;
            -*)
                return usage ("Unknown option: $1")
                ;;
            *)
                if [[ -n "$STACK_RESOLVER_ARG" ]]; then
                    return usage ("Cannot specify multiple resolvers: $1")
                fi
                STACK_RESOLVER_ARG="$1"
                shift
                ;;
        esac
    done
    return 0
}

function push () {
    local
    [[ $PUSH = false ]] || docker push "$1"
}

function main () {
    local retval = parseCmd ()
    if [ retval != 0 ]; then
        exit $retval
    fi;
}

main "$@"