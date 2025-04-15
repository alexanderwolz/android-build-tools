#!/bin/bash
# Copyright (C) 2025 Alexander Wolz <mail@alexanderwolz.de>

#ADJUST FOR YOUR ACTUAL AOSP OUT FOLDER CONTAINING THE IMAGES ..
AOSP_OUT="$HOME/Desktop/aosp_out/android-15.0.0_r26/tangorpro"
#$AOSP_OUT/*.img | xargs -n 1 basename

#INFO: flash the appropriate stock rom first, to get the newest bootloader, etc.

function deleteAndCreatePartition(){
    local PARTITION=$1_$SLOT
    echo "Recreating $PARTITION .."
    fastboot delete-logical-partition $PARTITION || exit 1
    fastboot create-logical-partition $PARTITION $(stat -f%z $AOSP_OUT/$1.img) || exit 1
}


##################
# START
##################

echo "-------------------------------"
echo " Whale Shark AAOS flash script "
echo "-------------------------------"

if ! fastboot devices 2> /dev/null | grep fastboot; then
    # adb reboot fastboot   vs  adb reboot bootloader
    echo ""
    echo "No fastboot devices found, please reboot into fastboot (adb reboot fastboot)"
    echo ""
    exit 1
fi

SLOT="b" #We only flash on slot B
ACTIVE_SLOT=$(fastboot getvar current-slot 2>&1 | grep "current-slot:" | grep -oE "a|b")

echo "-------------------------------"
echo "You are currently on slot: $ACTIVE_SLOT"
echo "-------------------------------"

if [[ "$SLOT" != "$ACTIVE_SLOT" ]]; then
    while true; do
        read -p "Your are not on slot $SLOT, we need to switch. proceed? [y/n] " selection
        case $selection in
            [y]*) break ;;
            [n]*) exit ;;
            *) echo "Please answer y or n." ;;
        esac
    done
    fastboot set_active $SLOT || exit 1
fi


fastboot reboot fastboot # we need to be in fastbootd from here!


# Dynamic Partitions
echo "-------------------------------------------------------------"
deleteAndCreatePartition system || exit 1
fastboot flash system_$SLOT $AOSP_OUT/system.img || exit 1
echo "-------------------------------------------------------------"
deleteAndCreatePartition vendor || exit 1
fastboot flash vendor_$SLOT $AOSP_OUT/vendor.img || exit 1
echo "-------------------------------------------------------------"
deleteAndCreatePartition product || exit 1
fastboot flash product_$SLOT $AOSP_OUT/product.img || exit 1
echo "-------------------------------------------------------------"
deleteAndCreatePartition system_ext || exit 1
fastboot flash system_ext_$SLOT $AOSP_OUT/system_ext.img || exit 1
echo "-------------------------------------------------------------"
deleteAndCreatePartition vendor_dlkm || exit 1
fastboot flash vendor_dlkm_$SLOT $AOSP_OUT/vendor_dlkm.img || exit 1
echo "-------------------------------------------------------------"
deleteAndCreatePartition system_dlkm || exit 1
fastboot flash system_dlkm_$SLOT $AOSP_OUT/system_dlkm.img || exit 1
echo "-------------------------------------------------------------"
deleteAndCreatePartition vendor || exit 1
fastboot flash vendor_$SLOT $AOSP_OUT/vendor.img || exit 1


# Kernel and boot
echo "-------------------------------------------------------------"
fastboot flash boot_$SLOT $AOSP_OUT/boot.img || exit 1
echo "-------------------------------------------------------------"
fastboot flash init_boot_$SLOT $AOSP_OUT/init_boot.img || exit 1
echo "-------------------------------------------------------------"
fastboot flash vendor_boot_$SLOT $AOSP_OUT/vendor_boot.img || exit 1
echo "-------------------------------------------------------------"
fastboot flash vendor_kernel_boot_$SLOT $AOSP_OUT/vendor_kernel_boot.img || exit 1
echo "-------------------------------------------------------------"
fastboot flash dtbo_$SLOT $AOSP_OUT/dtbo.img || exit 1


# AVB-Meta (important!)
echo "-------------------------------------------------------------"
fastboot --disable-verity --disable-verification flash vbmeta_$SLOT $AOSP_OUT/vbmeta.img || exit 1
echo "-------------------------------------------------------------"
fastboot flash vbmeta_system_$SLOT $AOSP_OUT/vbmeta_system.img || exit 1
echo "-------------------------------------------------------------"
fastboot flash vbmeta_vendor_$SLOT $AOSP_OUT/vbmeta_vendor.img || exit 1


# Firmware
echo "-------------------------------------------------------------"
fastboot flash pvmfw_$SLOT $AOSP_OUT/pvmfw.img


# Userdata (is not an a/b partition but shared)
echo "-------------------------------------------------------------"
fastboot flash userdata $AOSP_OUT/userdata.img || exit 1

# wipe data and format
echo "-------------------------------------------------------------"
fastboot erase userdata
echo "-------------------------------------------------------------"
fastboot erase metadata
echo "-------------------------------------------------------------"
fastboot format userdata
echo "-------------------------------------------------------------"
fastboot format metadata
echo "-------------------------------------------------------------"


echo "-------------------------------------------------------------"
echo "--- Done, please reboot (fastboot reboot) --"
echo ""
#fastboot reboot