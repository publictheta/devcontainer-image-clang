#!/usr/bin/env bash
#
# CMake
#
# https://apt.kitware.com/
#

set -e

readonly REPO_LIST="/etc/apt/sources.list.d/kitware.list"
readonly REPO_KEY="/etc/apt/keyrings/apt.kitware.com.gpg"

# Suppress interactive prompts
export DEBIAN_FRONTEND=noninteractive

wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor -o $REPO_KEY
echo "deb [signed-by=${REPO_KEY}] https://apt.kitware.com/ubuntu/ $(lsb_release -sc) main" > $REPO_LIST

apt-get update
apt-get install -y --no-install-recommends cmake

apt-get clean -y
rm -rf /var/lib/apt/lists/*
