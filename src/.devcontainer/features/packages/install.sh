#!/usr/bin/env bash
#
# Packages
#

set -e

# Install extra tools
EXTRA=${EXTRA:-"false"}

# Install man pages
MAN=${MAN:-"false"}

# Packages to install (space separated)
PACKAGES=${PACKAGES:-""}

# Suppress interactive prompts
export DEBIAN_FRONTEND=noninteractive

fatal() {
    echo "[ERROR] $1" 1>&2
    exit 1
}

if [[ $PACKAGES =~ [,\;] ]]; then
    fatal "\"packages\" must be separated by spaces: ${PACKAGES}"
fi

pkgs=($PACKAGES)

# extra tools
if [ "$EXTRA" = "true" ]; then
    pkgs+=("htop")
    pkgs+=("iproute2")
    pkgs+=("less")
    pkgs+=("locales")
    pkgs+=("lsof")
    pkgs+=("make")
    pkgs+=("nano")
    pkgs+=("net-tools")
    pkgs+=("procps")
    pkgs+=("psmisc")
    pkgs+=("rsync")
    pkgs+=("strace")
    pkgs+=("tree")
    pkgs+=("zip")
fi

# man pages
if [ "$MAN" = "true" ]; then
    pkgs+=("man-db")
    pkgs+=("manpages")
    pkgs+=("manpages-dev")
    pkgs+=("manpages-posix")
    pkgs+=("manpages-posix-dev")
fi

apt-get update
apt-get install -y --no-install-recommends ${pkgs[@]}
apt-get clean -y
rm -rf /var/lib/apt/lists/*
