#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>

function printHelpMenu(){
    echo ""
    echo "usage: [options] [device-name]"
    echo "----------------------------"
    echo "  -a sync everything"
    echo "----------------------------"
    echo "  -h print this menu"
    echo ""
}


echo ""
echo "---------------------------------------------------------------"
echo "Synching Tool"
echo "---------------------------------------------------------------"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh" || exit 1

while getopts a?h opt; do
    case $opt in
    a)
        SYNC_ALL=1
        echo "!! Syncing everything !!"
        echo "---------------------------------------------------------------"
        ;;
    h)
        printHelpMenu
        exit 0
        ;;
    esac
done

shift $((OPTIND - 1))
[ "${1:-}" = "--" ] && shift

setRemoteProductParent

echo "Reading device list from $SSH_HOST .."
DEVICE_NAMES=($($SSH_OPTS $SSH_USER@$SSH_HOST ls $REMOTE_PRODUCT_PARENT_FOLDER))
if [ ${#DEVICE_NAMES[@]} == 0 ]; then
	echo "There are no devices available at $REMOTE_PRODUCT_PARENT_FOLDER"
	echo ""
	exit 1
fi

if [ ! -z $1 ]; then
    DEVICE_NAME=$1
else
    chooseDevice "${DEVICE_NAMES[@]}" || exit 1
    echo ""
    echo "---------------------------------------------------------------"
fi

if [[ ${DEVICE_NAMES[@]} =~ $DEVICE_NAME ]]; then
    echo "Synching AOSP device '$DEVICE_NAME' in $REMOTE_AOSP_HOME from $SSH_HOST .."
    echo "Using local folder $LOCAL_AOSP_HOME"
    echo "---------------------------------------------------------------"
else
    echo "Device $DEVICE does not exist"
    echo ""
    exit 1
fi

echo ""
while true; do
    read -p "Do you wish to synch '$DEVICE_NAME'? [y/n] " selection
    case $selection in
    [y]*) break ;;
    [n]*) exit ;;
    *) echo "Please answer y or n." ;;
    esac
done

REMOTE_PRODUCT_FOLDER="$REMOTE_PRODUCT_PARENT_FOLDER/$DEVICE_NAME"

BEGIN=$(date -u +%s)

mkdir -p $LOCAL_AOSP_HOME

if [ ! -z $SYNC_ALL ]; then
    #copy everything from $ANDROID_PRODUCT_OUT
    rsync -avh -e "$SSH_OPTS" --delete "$SSH_USER@$SSH_HOST":$REMOTE_PRODUCT_FOLDER $LOCAL_AOSP_HOME
else
    #copy everything from $ANDROID_PRODUCT_OUT except exclude folders
    rsync -avh -e "$SSH_OPTS" --delete --exclude apex --exclude symbols --exclude obj --exclude obj_arm --exclude obj_x86 \
    "$SSH_USER@$SSH_HOST":$REMOTE_PRODUCT_FOLDER $LOCAL_AOSP_HOME
fi

DURATION=$(($(date -u +%s)-$BEGIN))
echo "---------------------------------------------------------------"
echo "AOSP product can be found at $LOCAL_AOSP_HOME/$DEVICE_NAME"
echo "---------------------------------------------------------------"
echo "Finished Sync - took $(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds"
echo "---------------------------------------------------------------"
echo "" #newline
