#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
ROOT_DIR=$(pwd)
popd > /dev/null

DOCKERIMAGE_REPO="ueisele/haskell-stack-hie"
GITHUB_REPO_URL="https://github.com/ueisele/docker-haskell-hie"

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

function resolveRepo () {
    pushd . > /dev/null
    cd $ROOT_DIR
    git config --get remote.origin.url
    popd > /dev/null
}

function resolveCommit () {
    pushd . > /dev/null
    cd $ROOT_DIR
    git rev-list --abbrev-commit --abbrev=7 -1 master ${DOCKERFILE_DIR}
    popd > /dev/null
}

function resolveBuildTimestamp() {
    local created=$(docker inspect --format "{{ index .Created }}" "${DOCKERIMAGE_REPO}:${DOCKERFILE_DIR}")
    date --utc -d "${created}" +'%Y%m%dT%H%M%Z'
}

function resolveImageLabel () {
    local label=${1:-"Missing label name as first parameter!"}
    docker inspect \
        --format "{{ index .Config.Labels \"${label}\"}}" \
        "${DOCKERIMAGE_REPO}:${DOCKERFILE_DIR}"
}

function resolveImageTags () {
    local resolver=$(resolveImageLabel "stack.resolver")
    local hie=$(resolveImageLabel "hie.version")
    local timestamp=$(resolveBuildTimestamp)
    local commit=$(resolveImageLabel "source.git.commit")
    echo "${resolver}" "${resolver}-${hie}" "${resolver}-${hie}-${timestamp}-${commit}"
}

function build () {
    local gitRepo=$(resolveRepo)
    local commit=$(resolveCommit)
    local dockerfileUrl=${GITHUB_REPO_URL}/blob/${commit}/${DOCKERFILE_DIR}/Dockerfile
    pushd . > /dev/null
    cd $ROOT_DIR
    docker build -t ${DOCKERIMAGE_REPO}:${DOCKERFILE_DIR} \
        -f ${DOCKERFILE_DIR}/Dockerfile \
        --build-arg SOURCE_GIT_REPOSITORY=${gitRepo} \
        --build-arg SOURCE_GIT_COMMIT=${commit} \
        --build-arg DOCKERFILE_URL=${dockerfileUrl} \
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