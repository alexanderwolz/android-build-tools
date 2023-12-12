#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>


echo ""
echo "---------------------------------------------------------------"
echo "Synching Tool"
echo "---------------------------------------------------------------"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh" || exit 1

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
fi

if [ -z $DEVICE_NAME ]; then
    echo "Something's wrong, try again"
    echo ""
    exit 1
fi

if [[ ${DEVICE_NAMES[@]} =~ $DEVICE_NAME ]]; then
    echo "Synching AOSP device '$DEVICE_NAME' from $SSH_HOST .."
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
rsync -aP -e "$SSH_OPTS" "$SSH_USER@$SSH_HOST":$REMOTE_PRODUCT_FOLDER $LOCAL_AOSP_SYNCH
DURATION=$(($(date -u +%s)-$BEGIN))
echo "---------------------------------------------------------------"
echo "AOSP product can be found at $LOCAL_AOSP_SYNCH/$DEVICE_NAME"
echo "---------------------------------------------------------------"
echo "Finished Sync - took $(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds"
echo "---------------------------------------------------------------"
echo "" #newline
