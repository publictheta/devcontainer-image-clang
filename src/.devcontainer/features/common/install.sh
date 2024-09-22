#!/usr/bin/env bash
#
# Common
#

set -e

# Suppress interactive prompts
export DEBIAN_FRONTEND=noninteractive

apt-get update

pkgs=()
pkgs+=("ca-certificates")
pkgs+=("curl")
pkgs+=("gnupg")
pkgs+=("lsb-release")
pkgs+=("ssh")
pkgs+=("sudo")
pkgs+=("unzip")
pkgs+=("wget")

apt-get install -y --no-install-recommends "${pkgs[@]}"
apt-get clean -y
rm -rf /var/lib/apt/lists/*
