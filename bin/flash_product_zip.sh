#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#copied from The Android Open Source Project
if ! [ $($(which fastboot) --version | grep "version" | cut -c18-23 | sed 's/\.//g' ) -ge 3301 ]; then
  echo "fastboot too old; please download the latest version at https://developer.android.com/studio/releases/platform-tools.html"
  exit 1
fi

echo ""
echo "---------------------------------------------------------------"
echo "Flashing tool"
echo "---------------------------------------------------------------"

ZIP_FILE=$1

if [ -z $ZIP_FILE ]; then
    echo "Please specify zip file"
    exit 1
fi

while true; do
    read -p "Do you wish to flash? [y/n] " selection
    case $selection in
    [y]*) break ;;
    [n]*) exit ;;
    *) echo "Please answer y or n." ;;
    esac
done

adb reboot bootloader

if [ -f "$SCRIPT_DIR/bootloader.img" ]; then
    fastboot flash bootloader "$SCRIPT_DIR/bootloader.img"
    fastboot reboot-bootloader
    sleep 5
fi

fastboot -w update $ZIP_FILE



# now comes the tricky part with vendor files..

echo "waiting for device to come up .."
adb wait-for-device

echo "setting adb root .."
adb root

VERITY_MODE=$(adb shell getprop ro.boot.veritymode)
if [ "$VERITY_MODE" == "enabled" ]  || [ "$VERITY_MODE" = "enforcing" ]; then
    echo "disabling verity .."
    adb disable-verity
    sleep 3

    echo "rebooting .."
    adb reboot

    echo "waiting for device to come up .."
    adb wait-for-device

    echo "setting adb root .."
    adb root

    sleep 2
else
    echo "Verity is already disabled, skipping"
fi

echo "Remounting .."
adb remount
if [ "$?" -ne 0 ]; then
    echo "Committing checkpoint .."
    adb shell vdc checkpoint commitChanges
    adb remount

    echo "rebooting .."
    adb reboot

    echo "waiting for device to come up .."
    adb wait-for-device

    echo "setting adb root .."
    adb root

    echo "Try remount again .."
    adb remount
fi

#extracting vendor from zip to tmp folder
ANDROID_PRODUCT_OUT_TMP="$SCRIPT_DIR/.product_out_tmp"
rm -rf $ANDROID_PRODUCT_OUT_TMP
mkdir -p $ANDROID_PRODUCT_OUT_TMP
unzip $ZIP_FILE "vendor/*" -d "$ANDROID_PRODUCT_OUT_TMP" > /dev/null || exit 1
export ANDROID_PRODUCT_OUT=$ANDROID_PRODUCT_OUT_TMP

echo "Syncing vendor partition .."
adb sync vendor

echo "Rebooting .."
adb reboot || exit 1

rm -rf $ANDROID_PRODUCT_OUT_TMP

echo "done"