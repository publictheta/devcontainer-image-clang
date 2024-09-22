#!/usr/bin/env bash
#
# Common
#

set -e

# The default locale to set
LOCALE=${LOCALE:-""}

# Additional locales to install
EXTRA_LOCALES=${EXTRAlocales:-""}

# Suppress interactive prompts
export DEBIAN_FRONTEND=noninteractive

fatal() {
    echo "[ERROR] $1" 1>&2
    exit 1
}

info() {
    echo "[INFO] $1"
}

if [[ $EXTRA_LOCALES =~ [,\;] ]]; then
    fatal "\"extraLocales\" must be separated by spaces: ${EXTRA_LOCALES}"
fi

locales=()

if [ -n "$LOCALE" ]; then
    locales+=($LOCALE)
fi

if [ -n "$EXTRA_LOCALES" ]; then
    locales+=($EXTRA_LOCALES)
fi

if [ ${#locales[@]} -eq 0 ]; then
    info "No locales to install. Exiting..."
    exit 0
fi

apt-get update
apt-get install -y --no-install-recommends "locales"
apt-get clean -y
rm -rf /var/lib/apt/lists/*

not_supported=()

for locale in ${locales[@]}; do
    if ! grep -q "^$locale" /usr/share/i18n/SUPPORTED; then
        not_supported+=($locale)
    fi
done

if [ ${#not_supported[@]} -gt 0 ]; then
    fatal "The following locales are not supported: ${not_supported[@]}"
fi

locale-gen ${locales[@]}

update-locale LANG=${LOCALE}

info "Locales installed: ${locales[@]}"
info "Default locale: ${LOCALE}"
