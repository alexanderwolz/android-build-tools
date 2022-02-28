#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ENV_FILE_NAME=".env"
ENV_FILE="$SCRIPT_DIR/$ENV_FILE_NAME"

# Properties needed from env file
# 	SSH_AOSP_HOME="~/aosp"
# 	SSH_HOST="server.de"
# 	SSH_USER="root"
# 	SSH_PORT="22"
# 	SSH_KEY="~/.ssh/id_rsa"

if [ -f $ENV_FILE ]; then
	source $ENV_FILE # overwrite properties above using .env file
else
	echo "Please create env file '$ENV_FILE_NAME'"
	exit 1
fi

REMOTE="$SSH_USER@$SSH_HOST"

if [ ! -z $SSH_KEY ]; then
	SSH_OPTS+=" -i $SSH_KEY"
fi
if [ ! -z $SSH_PORT ]; then
	SSH_OPTS+=" -p $SSH_PORT"
fi

SSH_OPTS="ssh$SSH_OPTS"

if [ ! $ANDROID_HOME ]; then
	echo "Please set \$ANDROID_HOME variable (points to sdk folder)"
	exit 1
fi

DEVICE=$1
if [ -z $DEVICE ]; then
	DEVICE="catfish"
fi

echo "Syncing target: '$DEVICE' from $SSH_HOST"

TARGET="$SSH_AOSP_HOME/out/target/product/$DEVICE"
SYSIMG_DIR="$ANDROID_HOME/system-images/android-31/$DEVICE"
mkdir -p $SYSIMG_DIR

#source props missing
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/kernel-ranchu" $SYSIMG_DIR"/kernel-ranchu-64" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/ramdisk-qemu.img" $SYSIMG_DIR"/ramdisk.img" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/system-qemu.img" $SYSIMG_DIR"/system.img" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/VerifiedBootParams.textproto" $SYSIMG_DIR"/VerifiedBootParams.textproto" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/advancedFeatures.ini" $SYSIMG_DIR"/advancedFeatures.ini" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/system/build.prop" $SYSIMG_DIR"/build.prop" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/encryptionkey.img" $SYSIMG_DIR"/encryptionkey.img" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/userdata.img" $SYSIMG_DIR"/userdata.img" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/vendor-qemu.img" $SYSIMG_DIR"/vendor.img" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/data" $SYSIMG_DIR || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/product-qemu.img" $SYSIMG_DIR"/product.img" || exit 1
rsync -av -e "$SSH_OPTS" $REMOTE:$TARGET"/system_ext-qemu.img" $SYSIMG_DIR"/system_ext.img" || exit 1