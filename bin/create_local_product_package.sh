#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>


function add() {
    local ELEMENT=$ANDROID_PRODUCT_OUT/$1
    if [ -f $ELEMENT ] || [ -d $ELEMENT ]; then
        if [ ! -z $2 ]; then
            cp -rf $ELEMENT "$PACKAGE_IMAGE_DIR/$2"
        else
            cp -rf $ELEMENT "$PACKAGE_IMAGE_DIR/$1"
        fi
    else
        echo "Skipping - No such file: $1"
    fi
}

echo ""
echo "---------------------------------------------------------------"
echo "Create product package Tool"
echo "---------------------------------------------------------------"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh" || exit 1

setLocalAOSPHome

DEVICE_NAMES=($(ls $LOCAL_AOSP_HOME))
if [ ${#DEVICE_NAMES[@]} == 0 ]; then
	echo "There are no devices available at $LOCAL_AOSP_HOME"
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

ANDROID_PRODUCT_OUT="$LOCAL_AOSP_HOME/$DEVICE_NAME"
export ANDROID_PRODUCT_OUT

echo "---------------------------------------------------------------"
echo "Using product: $DEVICE_NAME"
echo "---------------------------------------------------------------"

echo ""
while true; do
    read -p "Do you wish to create package for '$DEVICE_NAME'? [y/n] " selection
    case $selection in
    [y]*) break ;;
    [n]*) exit ;;
    *) echo "Please answer y or n." ;;
    esac
done

BUILD_PROPERTIES_FILE="$ANDROID_PRODUCT_OUT/system/build.prop"

if [ ! -f $BUILD_PROPERTIES_FILE ]; then
    echo "Missing file $BUILD_PROPERTIES_FILE"
    exit 1
fi

BUILD_PROPERTIES=$(cat $BUILD_PROPERTIES_FILE) || exit 1

API_LEVEL=$(echo "$BUILD_PROPERTIES" | grep ro.build.version.sdk= | cut -d'=' -f2) || exit 1
BUILD_FLAVOR=$(echo "$BUILD_PROPERTIES" | grep ro.build.flavor= | cut -d'=' -f2) || exit 1
PRODUCT_NAME=$(echo "$BUILD_PROPERTIES"| grep ro.build.product= | cut -d'=' -f2) || exit 1
ANDROID_VERSION=$(echo "$BUILD_PROPERTIES" | grep ro.system.build.version.release= | cut -d'=' -f2) || exit 1
BUILD_TYPE=$(echo "$BUILD_PROPERTIES" | grep ro.system.build.type= | cut -d'=' -f2) || exit 1
BUILD_ID=$(echo "$BUILD_PROPERTIES" | grep ro.system.build.id= | cut -d'=' -f2) || exit 1

NOW=$(date +"%Y%m%d-%H%M%S")
BEGIN=$(date -u +%s)

PACKAGE_ROOT=$PARENT_DIR"/packages"
PACKAGE_DIR=$PACKAGE_ROOT"/"$BUILD_FLAVOR"_android"$ANDROID_VERSION"_"$NOW
PACKAGE_IMAGE_DIR=$PACKAGE_DIR"/images-"$BUILD_FLAVOR"_android"$ANDROID_VERSION

PACKAGE_IMAGE_ZIP=$PACKAGE_IMAGE_DIR.zip
PACKAGE_DIR_ZIP=$PACKAGE_DIR.zip

mkdir -p $PACKAGE_IMAGE_DIR || exit 1

echo "Checking files .."

FLASH_FILE=$PACKAGE_DIR/flash.sh
cp $SCRIPT_DIR/flash_product_zip.sh $FLASH_FILE
sed -i '' -e "s/ZIP_FILE=\$1/ZIP_FILE=$(basename $PACKAGE_IMAGE_ZIP)/g" $FLASH_FILE
chmod +x $FLASH_FILE

BOOTLOADER="$ANDROID_PRODUCT_OUT/bootloader.img"
if [ -f $BOOTLOADER ]; then
    echo "Adding bootloader.img"
    cp $BOOTLOADER $PACKAGE_DIR || exit 1
fi

add system/build.prop build.prop
add android-info.txt
add boot.img
add dtbo.img
add init_boot.img
add product.img
add pvmfw.img
add super_empty.img
add system_dlkm.img
add system_ext.img
add system_other.img
add system.img
add vbmeta_system.img
add vbmeta_vendor.img
add vbmeta.img
add vendor_boot.img
add vendor_dlkm.img
add vendor_kernel_boot.img
add vendor.img
add vendor/ #TODO merge this into image

echo "Zipping images .."
pushd $PACKAGE_IMAGE_DIR > /dev/null
zip -r $PACKAGE_IMAGE_ZIP . || exit 1
popd > /dev/null

#zip -r -j $PACKAGE_IMAGE_ZIP $PACKAGE_IMAGE_DIR/* || exit 1
rm -rf $PACKAGE_IMAGE_DIR || exit 1

echo "Zipping all content .."
zip -j $PACKAGE_DIR_ZIP $PACKAGE_DIR/* || exit 1

echo "Cleaning up .."
rm -rf $PACKAGE_DIR


DURATION=$(($(date -u +%s)-$BEGIN))
echo "---------------------------------------------------------------"
echo "Package can be found at ../packages/$(basename $PACKAGE_DIR_ZIP)"
echo "---------------------------------------------------------------"
echo "Finished - took $(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds"
echo "---------------------------------------------------------------"
echo "" #newline