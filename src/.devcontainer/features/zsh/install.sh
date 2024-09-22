#!/usr/bin/env bash
#
# Zsh
#

set -e

# Install zsh for root
ROOT=${ROOT:-"true"}

# Install zsh for users in /home
HOME=${HOME:-"true"}

# Oh My Zsh theme
THEME=${THEME:-"robbyrussell"}

# Oh My Zsh plugins (space separated)
PLUGINS=${PLUGINS:-"git"}

# Suppress interactive prompts
export DEBIAN_FRONTEND=noninteractive

fatal() {
    echo "[ERROR] $1" 1>&2
    exit 1
}

info() {
    echo "[INFO] $1"
}

if [[ $PLUGINS =~ [,\;] ]]; then
    fatal "\"plugins\" must be separated by spaces: ${PLUGINS}"
fi

# users[user]=home
declare -A users=()

if [ "$ROOT" = "true" ]; then
    if [ ! -d /root ]; then
        fatal "/root does not exist."
    fi

    users["root"]=/root
fi

if [ "$HOME" = "true" ]; then
    for home in /home/*; do
        if [ -d "$home" ]; then
            user=$(basename $home)
            users[$user]=$home
        fi
    done
fi

apt-get update
apt-get install -y --no-install-recommends zsh
apt-get clean -y
rm -rf /var/lib/apt/lists/*

if [ ${#users[@]} -eq 0 ]; then
    exit 0
fi

# Follows the similar approach as what `common-utils` does:
#
# - https://github.com/devcontainers/features/blob/main/src/common-utils/main.sh
#
# See also:
#
# - https://github.com/ohmyzsh/ohmyzsh/?tab=readme-ov-file#manual-installation
# - https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh
#

readonly REPO="ohmyzsh/ohmyzsh"
readonly REMOTE="https://github.com/${REPO}.git"
readonly BRANCH="master"

readonly HEADER=$(cat <<'EOF'
# Oh My Zsh
#
# https://ohmyz.sh/
#
# See also:
#
# - https://github.com/ohmyzsh/ohmyzsh/blob/master/templates/zshrc.zsh-template
# - https://github.com/ohmyzsh/ohmyzsh/wiki/Customization
#

export ZSH="$HOME/.oh-my-zsh"
EOF
)

readonly FOOTER=$(cat <<'EOF'
source $ZSH/oh-my-zsh.sh
EOF
)

install_oh_my_zsh() {

    local user=$1
    local home=$2

    if [ -d "$home/.oh-my-zsh" ]; then
        info "Oh My Zsh is already installed for $user"
        return
    fi

    info "Installing Oh My Zsh for $user"

    git clone \
        --depth=1 \
        --branch $BRANCH \
        -c fsck.zeroPaddedFilemode=ignore \
        -c fetch.fsck.zeroPaddedFilemode=ignore \
        -c receive.fsck.zeroPaddedFilemode=ignore \
        $REMOTE $home/.oh-my-zsh

    cd $home/.oh-my-zsh

    git repack -a -d -f --depth=1 --window=1

    cd -

    group=$(id -gn $user)

    chown -R $user:$group $home/.oh-my-zsh

    echo "$HEADER" > $home/.zshrc
    echo "" >> $home/.zshrc
    echo "ZSH_THEME=\"$THEME\"" >> $home/.zshrc
    echo "" >> $home/.zshrc
    echo "plugins=($PLUGINS)" >> $home/.zshrc
    echo "" >> $home/.zshrc
    echo "$FOOTER" >> $home/.zshrc

    chown $user:$group $home/.zshrc
}

copy_oh_my_zsh() {
    local user=$1
    local home=$2
    local src_home=$3

    if [ -d "$home/.oh-my-zsh" ]; then
        info "Oh My Zsh is already installed for $user"
        return
    fi

    if [ -f "$home/.zshrc" ]; then
        cp -f $home/.zshrc $home/.zshrc.pre-oh-my-zsh
    fi

    info "Copying Oh My Zsh for $user"

    cp -rf $src_home/.oh-my-zsh $home
    cp -f $src_home/.zshrc $home

    group=$(id -gn $user)

    chown -R $user:$group $home/.oh-my-zsh
    chown $user:$group $home/.zshrc
}

first_user=""

for user in "${!users[@]}"; do
    home=${users[$user]}

    info "Setting up zsh for $user ($home)"

    if [ -z "$first_user" ]; then
        install_oh_my_zsh $user $home
        first_user=$user
    else
        copy_oh_my_zsh $user $home ${users[$first_user]}
    fi

    chsh -s /usr/bin/zsh $user
done
