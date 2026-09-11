#!/usr/bin/env bash

set -Eeuo pipefail

REPO_URL="https://github.com/st3w/neo.git"
BUILD_DIR=""
MAKE_CMD="make"

log() {
    printf '[neo-installer] %s\n' "$*"
}

die() {
    printf '[neo-installer] ERROR: %s\n' "$*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

cleanup() {
    if [[ -n "${BUILD_DIR}" && -d "${BUILD_DIR}" ]]; then
        rm -rf "${BUILD_DIR}"
    fi
}
trap cleanup EXIT

require_sudo() {
    if [[ "$(id -u)" -ne 0 ]] && ! command_exists sudo; then
        die "sudo is required to install system packages and neo."
    fi
}

as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

detect_platform() {
    case "$(uname -s)" in
        Darwin)
            PLATFORM="macos"
            ;;
        Linux)
            [[ -r /etc/os-release ]] || die "Cannot determine Linux distribution: /etc/os-release is missing."
            # shellcheck disable=SC1091
            . /etc/os-release
            case "${ID:-}" in
                arch|manjaro|endeavouros)
                    PLATFORM="arch"
                    ;;
                debian|ubuntu|linuxmint|pop|kali|raspbian)
                    PLATFORM="debian"
                    ;;
                *)
                    case " ${ID_LIKE:-} " in
                        *" arch "*) PLATFORM="arch" ;;
                        *" debian "*|*" ubuntu "*) PLATFORM="debian" ;;
                        *) die "Unsupported Linux distribution: ${PRETTY_NAME:-${ID:-unknown}}" ;;
                    esac
                    ;;
            esac
            ;;
        FreeBSD)
            PLATFORM="freebsd"
            MAKE_CMD="gmake"
            ;;
        *)
            die "Unsupported operating system: $(uname -s)"
            ;;
    esac
}

install_dependencies() {
    case "${PLATFORM}" in
        macos)
            command_exists brew || die "Homebrew is required on macOS. Install it from https://brew.sh and run this installer again."
            log "Installing build dependencies with Homebrew..."
            brew install autoconf automake libtool ncurses pkg-config git
            ;;
        arch)
            require_sudo
            log "Installing build dependencies with pacman..."
            as_root pacman -S --needed --noconfirm base-devel autoconf automake libtool ncurses git
            ;;
        debian)
            require_sudo
            log "Installing build dependencies with apt..."
            as_root apt-get update
            as_root apt-get install -y build-essential autoconf automake libtool libncurses-dev pkg-config git
            ;;
        freebsd)
            require_sudo
            log "Installing build dependencies with pkg..."
            as_root pkg install -y autoconf automake libtool ncurses pkgconf git gmake
            ;;
    esac
}

configure_project() {
    log "Running autogen.sh..."
    ./autogen.sh

    if [[ "${PLATFORM}" == "macos" ]]; then
        local ncurses_prefix
        ncurses_prefix="$(brew --prefix ncurses)"
        log "Configuring with Homebrew ncurses..."
        CPPFLAGS="-I${ncurses_prefix}/include" \
        LDFLAGS="-L${ncurses_prefix}/lib" \
        PKG_CONFIG_PATH="${ncurses_prefix}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}" \
        ./configure
    else
        log "Configuring project..."
        ./configure
    fi
}

build_project() {
    local jobs=2

    if command_exists getconf; then
        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')"
    elif command_exists sysctl; then
        jobs="$(sysctl -n hw.ncpu 2>/dev/null || printf '2')"
    fi

    [[ "${jobs}" =~ ^[0-9]+$ ]] || jobs=2

    log "Building neo with ${jobs} job(s)..."
    "${MAKE_CMD}" -j"${jobs}"
}

install_project() {
    require_sudo
    log "Installing neo using the project's make install target..."
    if [[ "$(id -u)" -eq 0 ]]; then
        "${MAKE_CMD}" install
    else
        sudo "${MAKE_CMD}" install
    fi
}

verify_installation() {
    if command_exists neo; then
        log "Installation complete: $(command -v neo)"
        log "Run 'neo' to start the application."
    else
        log "Installation completed, but 'neo' is not currently on PATH."
        log "Check the installation prefix reported by ./configure."
    fi
}

main() {
    log "Neo installer"
    detect_platform
    log "Detected platform: ${PLATFORM}"

    install_dependencies

    command_exists git || die "git is required but was not found after dependency installation."

    BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/neo-build.XXXXXX")"
    log "Cloning ${REPO_URL}..."
    git clone --depth 1 "${REPO_URL}" "${BUILD_DIR}/neo"

    cd "${BUILD_DIR}/neo"
    configure_project
    build_project
    install_project
    verify_installation
}

main "$@"
