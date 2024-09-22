#!/usr/bin/env bash
#
# Git
#
# https://launchpad.net/~git-core/+archive/ubuntu/ppa
#

set -e

# Suppress interactive prompts
export DEBIAN_FRONTEND=noninteractive

# From https://launchpad.net/~git-core/+archive/ubuntu/ppa
readonly KEY_ID="F911AB184317630C59970973E363C90F8F1B6217"

readonly REPO_LIST="/etc/apt/sources.list.d/git.list"
readonly REPO_KEY="/etc/apt/keyrings/git.gpg"

gpg --keyserver keyserver.ubuntu.com --recv-keys $KEY_ID
gpg --export $KEY_ID > $REPO_KEY
rm -rf /root/.gnupg

echo "deb [signed-by=${REPO_KEY}] http://ppa.launchpad.net/git-core/ppa/ubuntu $(lsb_release -sc) main" > $REPO_LIST

apt-get update
apt-get install -y --no-install-recommends git
apt-get clean -y
rm -rf /var/lib/apt/lists/*
