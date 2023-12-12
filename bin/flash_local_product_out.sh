#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>


function printHelpMenu(){
    echo ""
    echo "usage: [options] [device-name]"
    echo "----------------------------"
    echo "  -b flash bootloader"
    echo "  -f flash images"
    echo "  -v synch vendor partition"
    echo "----------------------------"
    echo "  -h print this menu"
    echo ""
}

echo ""
echo "---------------------------------------------------------------"
echo "Flash Tool"
echo "---------------------------------------------------------------"

#copied from The Android Open Source Project
if ! [ $($(which fastboot) --version | grep "version" | cut -c18-23 | sed 's/\.//g' ) -ge 3301 ]; then
    echo "fastboot too old; please download the latest version at https://developer.android.com/studio/releases/platform-tools.html"
    exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh" || exit 1

FLASH_BOOTLOADER=0
FLASH_IMAGES=0
SYNCH_VENDOR=0

while getopts b?f?h?v opt; do
    case $opt in
    b)
        FLASH_BOOTLOADER=1
        ;;
    f)
        FLASH_IMAGES=1
        ;;
    h)
        printHelpMenu
        exit 0
        ;;
    v)
        SYNCH_VENDOR=1
        ;;
    esac
done

if [ $OPTIND -eq 1 ]; then 
    # no specific arguments, so flash images and vendor!
    FLASH_IMAGES=1
    SYNCH_VENDOR=1
fi

shift $((OPTIND - 1))
[ "${1:-}" = "--" ] && shift

if [ "$FLASH_BOOTLOADER" -eq 1 ]; then
    echo "Option: Flashing bootloader"
fi

if [ "$FLASH_IMAGES" -eq 1 ]; then
    echo "Option: Flashing base images"
fi

if [ "$SYNCH_VENDOR" -eq 1 ]; then
    echo "Option: Synching vendor partition"
fi

echo "---------------------------------------------------------------"
getConnectedAndroidDevices

if [ ${#CONNECTED_DEVICES[@]} == 0 ]; then
   echo "There are no connected devices!"
   exit 1
fi

echo "Connected Android devices:"
for DEVICE in "${CONNECTED_DEVICES[@]}"
do
    echo " - $DEVICE"
done

if [ ${#CONNECTED_DEVICES[@]} == 1 ]; then
    DEVICE_ID="${CONNECTED_DEVICES[0]}"
fi

if [[ ${#CONNECTED_DEVICES[@]} -gt 1 ]]; then
    echo "Please choose a device id!"
    exit 1
fi

$(fastboot devices | grep $DEVICE_ID > /dev/null)
IS_NOT_FASTBOOT=$?

DEVICE_NAMES=($(ls $LOCAL_AOSP_SYNCH))
if [ ${#DEVICE_NAMES[@]} == 0 ]; then
	echo "There are no devices available at $LOCAL_AOSP_SYNCH"
	echo ""
	exit 1
fi

if [ ! -z $1 ]; then
    DEVICE_NAME=$1
else
    echo "---------------------------------------------------------------"
    echo "Reading product device list .."
    chooseDevice "${DEVICE_NAMES[@]}" || exit 1
fi

if [ -z $DEVICE_NAME ]; then
    echo "Something's wrong, try again"
    echo ""
    exit 1
fi

ANDROID_PRODUCT_OUT="$LOCAL_AOSP_SYNCH/$DEVICE_NAME"
export ANDROID_PRODUCT_OUT

echo "---------------------------------------------------------------"
echo "Using product: $DEVICE_NAME"
echo "Using device: $DEVICE_ID"
echo "---------------------------------------------------------------"

echo ""
while true; do
    read -p "Do you wish to flash '$DEVICE_NAME' on device '$DEVICE_ID'? [y/n] " selection
    case $selection in
    [y]*) break ;;
    [n]*) exit ;;
    *) echo "Please answer y or n." ;;
    esac
done

if [[ "$FLASH_BOOTLOADER" -eq 1 ||  "$FLASH_IMAGES" -eq 1 ]]; then
    if [ "$IS_NOT_FASTBOOT" -eq 1 ]; then
        echo "Restarting to fastboot.."
        adb reboot bootloader || exit 1
    else
        echo "Device $DEVICE_ID is already on fastboot"
    fi
fi

if [ "$FLASH_BOOTLOADER" -eq 1 ]; then
    BOOTLOADER="$ANDROID_PRODUCT_OUT/bootloader.img"
    if [ -f $BOOTLOADER ]; then
        fastboot flash bootloader $BOOTLOADER
        fastboot reboot-bootloader
        sleep 5
    else
        echo "There is no bootloader image in $ANDROID_PRODUCT_OUT"
        exit 1
    fi
fi

if [ "$FLASH_IMAGES" -eq 1 ]; then
    echo Flashing files from $ANDROID_PRODUCT_OUT
    fastboot flashing unlock
    fastboot -w flashall
fi


if [ "$SYNCH_VENDOR" -eq 1 ]; then
    # now comes the tricky part with vendor files..

    if [ "$IS_NOT_FASTBOOT" -eq 0 ]; then
        echo "Restarting to normal bootup.."
        fastboot reboot || exit 1
        sleep 5
    fi

    echo "waiting for device to come up .."
    adb -s $DEVICE_ID wait-for-device

    echo "setting adb root .."
    adb -s $DEVICE_ID root

    VERITY_MODE=$(adb -s $DEVICE_ID shell getprop ro.boot.veritymode)
    if [ "$VERITY_MODE" == "enabled" ]; then
        echo "disabling verity .."
        adb disable-verity
        sleep 3

        echo "rebooting .."
        adb -s $DEVICE_ID reboot

        echo "waiting for device to come up .."
        adb -s $DEVICE_ID wait-for-device

        echo "setting adb root .."
        adb -s $DEVICE_ID root

        sleep 2
    else
        echo "Verity is already disabled, skipping"
    fi

    echo "Remounting .."
    adb -s $DEVICE_ID remount
    if [ "$?" -ne 0 ]; then
        echo "Committing checkpoint .."
        adb -s $DEVICE_ID shell vdc checkpoint commitChanges
        adb -s $DEVICE_ID remount

        echo "rebooting .."
        adb -s $DEVICE_ID reboot

        echo "waiting for device to come up .."
        adb -s $DEVICE_ID wait-for-device

        echo "setting adb root .."
        adb -s $DEVICE_ID root

        echo "Try remount again .."
        adb -s $DEVICE_ID remount
    fi

    echo "Syncing vendor partition .."
    adb -s $DEVICE_ID sync vendor

    echo "Rebooting .."
    adb -s $DEVICE_ID reboot
fi

echo "done"