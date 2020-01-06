#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
ROOT_DIR=$(pwd)
popd > /dev/null

DOCKERIMAGE_REPO="ueisele/haskell-stack-hie"

PUSH=false
BUILD=false
DOCKERFILE_DIR=""

function usage () {
    echo "$0: $1" >&2
    echo
    echo "Usage: $0 [--build] [--push] <directory e.g. lts-14>"
    echo "See README.md for more information."
    echo
    return 1
}

function parseCmd () {
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
                usage "Unknown option: $1"
                return $?
                ;;
            *)
                if [[ -n "$DOCKERFILE_DIR" ]]; then
                    usage "Cannot specify multiple directories: $1"
                    return $?
                fi
                DOCKERFILE_DIR="$1"
                shift
                ;;
        esac
    done
    if [ -z "${DOCKERFILE_DIR}" ]; then
        usage "Requires directory"
        return $?
    fi
    if [ ! -f "${DOCKERFILE_DIR}/Dockerfile" ]; then 
        usage "Missing Dockerfile: ${DOCKERFILE_DIR}/Dockerfile"
    fi
    return 0
}

function buildTimestamp() {
    date --utc -u +'%Y%m%dT%H%M%Z'
}

function resolveRepo () {
    git config --get remote.origin.url
}

function resolveCommit () {
    git rev-list --abbrev-commit --abbrev=7 -1 master ${DOCKERFILE_DIR}
}

function resolveImageLabel () {
    local label=${1:-"Missing label name as first parameter!"}
    docker inspect \
        --format "{{ index .Config.Labels \"${label}\"}}" \
        "${DOCKERIMAGE_REPO}:${DOCKERFILE_DIR}"
}

function resolveImageTags () {
    local resolver=$(resolveImageLabel "stack.resolver")
    local timestamp=$(resolveImageLabel "build.timestamp")
    local commit=$(resolveImageLabel "source.git.commit")
    echo "${resolver}" "${resolver}-${timestamp}-${commit}"
}

function build () {
    pushd . > /dev/null
    cd $ROOT_DIR
    docker build -t ${DOCKERIMAGE_REPO}:${DOCKERFILE_DIR} \
        -f ${DOCKERFILE_DIR}/Dockerfile \
        --build-arg BUILD_TIMESTAMP=$(buildTimestamp) \
        --build-arg SOURCE_GIT_REPOSITORY=$(resolveRepo) \
        --build-arg SOURCE_GIT_COMMIT=$(resolveCommit) \
        ${DOCKERFILE_DIR}
    popd > /dev/null
}

function tag () {
    for t in $(resolveImageTags); do
        docker tag "${DOCKERIMAGE_REPO}:${DOCKERFILE_DIR}" "${DOCKERIMAGE_REPO}:${t}"
    done
}

function push () {
    for t in $(resolveImageTags); do
        docker push "${DOCKERIMAGE_REPO}:${t}"
    done
}

function main () {
    parseCmd "$@"
    local retval=$?
    if [ $retval != 0 ]; then
        exit $retval
    fi

    if [ "$BUILD" = true ]; then
        build
        tag
    fi
    if [ "$PUSH" = true ]; then
        push
    fi
}

main "$@"