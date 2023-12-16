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
echo "Create emulator package Tool"
echo "---------------------------------------------------------------"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh" || exit 1

if [ -z $ANDROID_HOME ]; then
    echo "\$ANDROID_HOME is not set"
    echo ""
    exit 1
fi

## -- APIS

APIS=($(ls $ANDROID_HOME/system-images))

if [ ${#APIS[@]} == 0 ]; then
    echo "\$ANDROID_HOME does not contain any system images"
    echo ""
    exit 1
fi

if [ ${#APIS[@]} == 1 ]; then
    API=${APIS[0]}
else
    echo ""
    echo "There are several apis, please choose one:"
    for INDEX in "${!APIS[@]}"; do 
        let API_INDEX=${INDEX}+1
        echo "$API_INDEX. ${APIS[$INDEX]}"
    done
    echo ""
    echo "please choose an api:"
    read INPUT
    if [[ $INPUT ]] && [ $INPUT -eq $INPUT 2>/dev/null ]; then
        if [ "$INPUT" -lt "1" ]; then
            echo "You can't choose zero, except you are Chuck Norris :)"
            echo ""
            exit 1
        fi
        if [ "$INPUT" -gt "${#APIS[@]}" ]; then
            echo "There are only ${#APIS[@]} apis to choose from."
            echo ""
            exit 1
        fi
        INDEX="$((INPUT-1))" #its a valid number, so use the index
        API="${APIS[$INDEX]}"
    else
        API=$INPUT
    fi
    echo ""
fi

## -- products

PRODUCTS=($(ls $ANDROID_HOME/system-images/$API))

if [ ${#PRODUCTS[@]} == 0 ]; then
    echo "$API does not contain any products"
    echo ""
    exit 1
fi

if [ ${#PRODUCTS[@]} == 1 ]; then
    PRODUCT=${PRODUCTS[0]}
else
    echo ""
    echo "There are several products, please choose one:"
    for INDEX in "${!PRODUCTS[@]}"; do 
        let API_INDEX=${INDEX}+1
        echo "$API_INDEX. ${PRODUCTS[$INDEX]}"
    done
    echo ""
    echo "please choose a product:"
    read INPUT
    if [[ $INPUT ]] && [ $INPUT -eq $INPUT 2>/dev/null ]; then
        if [ "$INPUT" -lt "1" ]; then
            echo "You can't choose zero, except you are Chuck Norris :)"
            echo ""
            exit 1
        fi
        if [ "$INPUT" -gt "${#PRODUCTS[@]}" ]; then
            echo "There are only ${#PRODUCTS[@]} products to choose from."
            echo ""
            exit 1
        fi
        INDEX="$((INPUT-1))" #its a valid number, so use the index
        PRODUCT="${PRODUCTS[$INDEX]}"
    else
        PRODUCT=$PRODUCTS
    fi
    echo ""
fi

## -- architectures

ARCHS=($(ls $ANDROID_HOME/system-images/$API/$PRODUCT))

if [ ${#ARCHS[@]} == 0 ]; then
    echo "$API/$PRODUCT does not contain any architectures"
    echo ""
    exit 1
fi

if [ ${#ARCHS[@]} == 1 ]; then
    ARCH=${ARCHS[0]}
else
    echo ""
    echo "There are several architectures, please choose one:"
    for INDEX in "${!ARCHS[@]}"; do 
        let ARCH_INDEX=${INDEX}+1
        echo "$ARCH_INDEX. ${ARCHS[$INDEX]}"
    done
    echo ""
    echo "please choose an architecture:"
    read INPUT
    if [[ $INPUT ]] && [ $INPUT -eq $INPUT 2>/dev/null ]; then
        if [ "$INPUT" -lt "1" ]; then
            echo "You can't choose zero, except you are Chuck Norris :)"
            echo ""
            exit 1
        fi
        if [ "$INPUT" -gt "${#ARCHS[@]}" ]; then
            echo "There are only ${#ARCHS[@]} architectures to choose from."
            echo ""
            exit 1
        fi
        INDEX="$((INPUT-1))" #its a valid number, so use the index
        ARCH="${ARCHS[$INDEX]}"
    else
        ARCH=$ARCHS
    fi
    echo ""
fi





EMULATOR_RELATIVE_PATH="system-images/$API/$PRODUCT/$ARCH"
EMULATOR_HOME="$ANDROID_HOME/$EMULATOR_RELATIVE_PATH"
BUILD_PROPERTIES_FILE="$EMULATOR_HOME/build.prop"

if [ ! -f $BUILD_PROPERTIES_FILE ]; then
    echo "Missing file $BUILD_PROPERTIES_FILE"
    exit 1
fi

BUILD_PROPERTIES=$(cat $BUILD_PROPERTIES_FILE) || exit 1

API_LEVEL=$(cat $BUILD_PROPERTIES_FILE | grep ro.build.version.sdk= | cut -d'=' -f2) || exit 1
BUILD_FLAVOR=$(cat $BUILD_PROPERTIES_FILE | grep ro.build.flavor= | cut -d'=' -f2) || exit 1
PRODUCT_NAME=$(cat $BUILD_PROPERTIES_FILE | grep ro.build.product= | cut -d'=' -f2) || exit 1
ANDROID_VERSION=$(cat $BUILD_PROPERTIES_FILE | grep ro.system.build.version.release= | cut -d'=' -f2) || exit 1
BUILD_TYPE=$(cat $BUILD_PROPERTIES_FILE | grep ro.system.build.type= | cut -d'=' -f2) || exit 1
BUILD_ID=$(cat $BUILD_PROPERTIES_FILE | grep ro.system.build.id= | cut -d'=' -f2) || exit 1


echo "---------------------------------------------------------------"
echo "Emulator: $PRODUCT"
echo "Android:  $API"
echo "Arch:     $ARCH"
echo "Build:    $BUILD_FLAVOR"
echo "---------------------------------------------------------------"

echo ""
while true; do
    read -p "Do you wish to create emulator package? [y/n] " selection
    case $selection in
    [y]*) break ;;
    [n]*) exit ;;
    *) echo "Please answer y or n." ;;
    esac
done

NOW=$(date +"%Y%m%d-%H%M%S")
BEGIN=$(date -u +%s)


PACKAGE_ROOT=$PARENT_DIR"/packages"
PACKAGE_DIR=$PACKAGE_ROOT"/"$BUILD_FLAVOR"_android"$ANDROID_VERSION"_"$NOW
PACKAGE_DIR_ZIP=$PACKAGE_DIR.zip
EMULATOR_RELATIVE_PATH="system-images/$API/$PRODUCT/$ARCH"

mkdir -p $PACKAGE_DIR"/"$EMULATOR_RELATIVE_PATH || exit 1

echo "Copying images .."
cp -rf $EMULATOR_HOME/* $PACKAGE_DIR"/"$EMULATOR_RELATIVE_PATH

echo "Zipping all content .."
pushd $PACKAGE_DIR > /dev/null
zip -r $PACKAGE_DIR_ZIP . || exit 1
popd > /dev/null

echo "Cleaning up .."
rm -rf $PACKAGE_DIR


DURATION=$(($(date -u +%s)-$BEGIN))
echo "---------------------------------------------------------------"
echo "Package can be found at ../packages/$(basename $PACKAGE_DIR_ZIP)"
echo "---------------------------------------------------------------"
echo "Finished - took $(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds"
echo "---------------------------------------------------------------"
echo "" #newline