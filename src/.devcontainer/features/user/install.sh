#!/usr/bin/env bash
#
# User
#

set -e

# User name/UID/GID to set up
USER_NAME=${USERNAME:-"vscode"}
USER_UID=${USERUID:-"1000"}
USER_GID=${USERGID:-"1000"}

# Allows to rename the user if it already exists
RENAME=${RENAME:-"false"}

# Allows to increment the UID and GID if they are already in use
INCREMENT=${INCREMENT:-"false"}

# Maximum number of increments to try
readonly MAX_TRY=10

fatal() {
    echo "[ERROR] $1" 1>&2
    exit 1
}

# root must be 0:0
if [ "$USER_NAME" == "root" ]; then
    ROOT_GID=$(id -g root)
    ROOT_UID=$(id -u root)

    if [ "$USER_GID" != "$ROOT_GID" ]; then
        fatal "GID for root must be $ROOT_GID."
    fi

    if [ "$USER_UID" != "$ROOT_UID" ]; then
        fatal "UID for root must be $ROOT_UID."
    fi

    exit 0
fi

# validate UID and GID
readonly UID_MIN=$(grep "^UID_MIN" /etc/login.defs | awk '{print $2}')
readonly UID_MAX=$(grep "^UID_MAX" /etc/login.defs | awk '{print $2}')
readonly GID_MIN=$(grep "^GID_MIN" /etc/login.defs | awk '{print $2}')
readonly GID_MAX=$(grep "^GID_MAX" /etc/login.defs | awk '{print $2}')

if [ "$USER_UID" -lt "$UID_MIN" ] || [ "$USER_UID" -gt "$UID_MAX" ]; then
    fatal "UID is out of range: $USER_UID (min: $UID_MIN, max: $UID_MAX)"
fi

if [ "$USER_GID" -lt "$GID_MIN" ] || [ "$USER_GID" -gt "$GID_MAX" ]; then
    fatal "GID is out of range: $USER_GID (min: $GID_MIN, max: $GID_MAX)"
fi

# Possible results:
#
# - unchanged
# - modified
# - renamed
# - created
#
result="unchanged"

# " ($result$result_name)" will be appended next to the user name
result_name=""

# "$result_uid" will be appended next to the UID
result_uid=""

# "$result_gid" will be appended next to the GID
result_gid=""

# Set '*' if something is changed
name_dirty=""
uid_dirty=""
gid_dirty=""

modify_id_if_needed() {
    OLD_GID=$(id -g $USER_NAME)
    OLD_UID=$(id -u $USER_NAME)

    if [ "$USER_GID" != "$OLD_GID" ]; then
        if getent group $USER_GID; then
            fatal "GID $USER_GID is already in use."
        fi

        GROUP_NAME=$(id -gn $USER_NAME)

        groupmod -g $USER_GID $GROUP_NAME
        usermod -g $USER_GID $USER_NAME

        # Update the GID of any files owned by the group
        find / -xdev -gid $OLD_GID -exec chgrp -h $GROUP_NAME {} \;

        gid_dirty="*"
        result="modified"
        result_gid=" (from $OLD_GID)"
    fi

    if [ "$USER_UID" != "$OLD_UID" ]; then
        if getent passwd $USER_UID; then
            fatal "UID $USER_UID is already in use."
        fi

        usermod -u $USER_UID $USER_NAME

        # Update the UID of any files owned by the user
        find / -xdev -uid $OLD_UID -exec chown -h $USER_NAME {} \;

        uid_dirty="*"
        result="modified"
        result_uid=" (from $OLD_UID)"
    fi
}

rename_if_exists() {
    if ! getent passwd $USER_UID &>/dev/null; then
        return
    fi

    if ! getent group $USER_GID &>/dev/null; then
        return
    fi

    OLD_USER_NAME=$(getent passwd $USER_UID | cut -d: -f1)
    OLD_GROUP_NAME=$(getent group $USER_GID | cut -d: -f1)

    if [ $USER_GID != $(id -g $OLD_USER_NAME) ]; then
        fatal "Failed to rename: gid=$USER_GID($OLD_GROUP_NAME) is not the primary group of uid=$USER_UID($OLD_USER_NAME)"
    fi

    if [ "$OLD_GROUP_NAME" != "$OLD_USER_NAME" ]; then
        fatal "Failed to rename: the original group name ($OLD_GROUP_NAME) is not the same as the original user name ($OLD_USER_NAME)"
    fi

    groupmod -n $USER_NAME $OLD_GROUP_NAME
    usermod -l $USER_NAME -d /home/$USER_NAME -m $OLD_USER_NAME

    name_dirty="*"
    result="renamed"
    result_name=" from $OLD_USER_NAME"
}

create_user() {
    if getent group $USER_NAME &>/dev/null; then
        fatal "Group \"$USER_NAME\" already exists."
    fi

    if getent passwd $USER_UID &>/dev/null; then
        if [ "$INCREMENT" != "true" ]; then
            fatal "UID $USER_UID is already in use."
        fi

        for i in $(seq $MAX_TRY); do
            NEW_UID=$((USER_UID + i))

            if ! getent passwd $NEW_UID &>/dev/null; then
                USER_UID=$NEW_UID
                break
            fi
        done

        if [ "$USER_UID" == "$OLD_UID" ]; then
            fatal "Failed to find a unique UID in $MAX_TRY tries (starting from $USER_UID)."
        fi

        uid_dirty="*"
        result_uid=" (incremented from $OLD_UID)"
    fi

    if getent group $USER_GID &>/dev/null; then
        if [ "$INCREMENT" != "true" ]; then
            fatal "GID $USER_GID is already in use."
        fi

        for i in $(seq $MAX_TRY); do
            NEW_GID=$((USER_GID + i))

            if ! getent group $NEW_GID &>/dev/null; then
                USER_GID=$NEW_GID
                break
            fi
        done

        if [ "$USER_GID" == "$OLD_GID" ]; then
            fatal "Failed to find a unique GID in $MAX_TRY tries (starting from $USER_GID)."
        fi

        gid_dirty="*"
        result_gid=" (incremented from $OLD_GID)"
    fi

    USER_SHELL=$(getent passwd root | cut -d: -f7)

    groupadd -g $USER_GID $USER_NAME
    useradd -m -u $USER_UID -g $USER_GID -s $USER_SHELL $USER_NAME

    result="created"
}

if id -u $USER_NAME &>/dev/null; then
    modify_id_if_needed
else
    if [ "$RENAME" == "true" ]; then
        rename_if_exists
    fi

    if [ "$result" != "renamed" ]; then
        create_user
    fi
fi

echo "----------------------------------------"
echo "User:  $USER_NAME$name_dirty ($result$result_name)"
echo "UID:   $USER_UID$uid_dirty$result_uid"
echo "GID:   $USER_GID$gid_dirty$result_gid"
echo "----------------------------------------"

# Add user to sudoers
echo "$USER_NAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME
chmod 440 /etc/sudoers.d/$USER_NAME
