#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>


echo ""
echo "---------------------------------------------------------------"
echo "Synching Emulator Images Tool"
echo "---------------------------------------------------------------"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh" || exit 1

if [ ! $ANDROID_HOME ]; then
	echo "Please set \$ANDROID_HOME variable (points to sdk folder)"
	exit 1
fi

setRemoteProductParent

echo "Reading device list from $SSH_HOST .."
DEVICE_NAMES=($($SSH_OPTS $SSH_USER@$SSH_HOST ls $REMOTE_PRODUCT_PARENT_FOLDER))
if [ ${#DEVICE_NAMES[@]} == 0 ]; then
	echo "There are no devices available at $REMOTE_PRODUCT_PARENT_FOLDER"
	echo ""
	exit 1
fi

DEVICE_NAME=$1
if [ -z $DEVICE_NAME ]; then
	DEVICE_NAME="emulator64_arm64"
	echo "No device parameter given, using default device: $DEVICE_NAME"
fi

echo "---------------------------------------------------------------"
if [[ ${DEVICE_NAMES[@]} =~ $DEVICE_NAME ]]; then
  echo "Syncing target device '$DEVICE_NAME' in $REMOTE_AOSP_HOME from $SSH_HOST"
else
  echo "Device $DEVICE_NAME does not exist"
  echo ""
  exit 1
fi

TARGET="$REMOTE_PRODUCT_PARENT_FOLDER/$DEVICE_NAME"

BUILD_PROPERTIES=$($SSH_CMD cat $TARGET/system/build.prop)

API_LEVEL=$(echo "$BUILD_PROPERTIES" | grep ro.build.version.sdk= | cut -d'=' -f2) || exit 1
# TODO: switch to ro.system.product.cpu.abilist ??
ARCH=$(echo "$BUILD_PROPERTIES" | grep ro.product.cpu.abi= | cut -d'=' -f2) || exit 1
BUILD_FLAVOR=$(echo "$BUILD_PROPERTIES" | grep ro.build.flavor= | cut -d'=' -f2) || exit 1
TARGET_NAME=$(echo "$BUILD_FLAVOR" | cut -d'_' -f1)|| exit 1

echo "Product '$TARGET_NAME' has API level $API_LEVEL for arch $ARCH"

echo ""
while true; do
    read -p "Do you wish to synch '$TARGET_NAME' ($DEVICE_NAME)? [y/n] " selection
    case $selection in
    [y]*) break ;;
    [n]*) exit ;;
    *) echo "Please answer y or n." ;;
    esac
done

SYSIMG_DIR="$ANDROID_HOME/system-images/android-$API_LEVEL/$TARGET_NAME/$ARCH"
mkdir -p $SYSIMG_DIR

BEGIN=$(date -u +%s)
#source props missing
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/kernel-ranchu" $SYSIMG_DIR"/kernel-ranchu-64" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/ramdisk-qemu.img" $SYSIMG_DIR"/ramdisk.img" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/system-qemu.img" $SYSIMG_DIR"/system.img" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/VerifiedBootParams.textproto" $SYSIMG_DIR"/VerifiedBootParams.textproto" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/advancedFeatures.ini" $SYSIMG_DIR"/advancedFeatures.ini" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/system/build.prop" $SYSIMG_DIR"/build.prop" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/encryptionkey.img" $SYSIMG_DIR"/encryptionkey.img" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/userdata.img" $SYSIMG_DIR"/userdata.img" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/vendor-qemu.img" $SYSIMG_DIR"/vendor.img" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/data" $SYSIMG_DIR || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/product-qemu.img" $SYSIMG_DIR"/product.img" || exit 1
rsync -avP -e "$SSH_OPTS" $REMOTE:$TARGET"/system_ext-qemu.img" $SYSIMG_DIR"/system_ext.img" || exit 1
DURATION=$(($(date -u +%s)-$BEGIN))
echo ""
echo "---------------------------------------------------------------"
echo "Images can be found at $SYSIMG_DIR"
echo "---------------------------------------------------------------"
echo "Finished Sync - took $(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds"
echo "---------------------------------------------------------------"
echo "" #newline