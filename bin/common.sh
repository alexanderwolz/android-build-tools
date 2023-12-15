#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE_NAME=".env"
ENV_FILE="$PARENT_DIR/$ENV_FILE_NAME"

if [ -f $ENV_FILE ]; then
	source $ENV_FILE
else
	echo "Please create env file '$ENV_FILE'"
    echo ""
	exit 1
fi

if [ -z $SSH_HOST ]; then
	echo "Please set '\$SSH_HOST' in $ENV_FILE"
    echo ""
	exit 1
fi

if [ -z $SSH_USER ]; then
	echo "Please set '\$SSH_USER' in $ENV_FILE"
    echo ""
	exit 1
fi

if [ -z $REMOTE_AOSP_ROOT ]; then
	echo "Please set '\$REMOTE_AOSP_ROOT' in $ENV_FILE"
    echo ""
	exit 1
fi

if [ -z $LOCAL_AOSP_ROOT ]; then
	echo "Please set '\$LOCAL_AOSP_ROOT' in $ENV_FILE"
    echo ""
	exit 1
fi

if [ ! -z $SSH_KEY ]; then
	SSH_OPTS+=" -i $SSH_KEY"
fi

if [ ! -z $SSH_PORT ]; then
	SSH_OPTS+=" -p $SSH_PORT"
fi

REMOTE="$SSH_USER@$SSH_HOST"
SSH_OPTS="ssh$SSH_OPTS"
SSH_CMD="$SSH_OPTS $REMOTE"

function setLocalAOSPHome() {
    test -e $LOCAL_AOSP_ROOT/build/envsetup.sh > /dev/null
    if [ $? -eq 0 ]; then
        echo "this is an AOSP root folder"
        LOCAL_AOSP_HOME=$LOCAL_AOSP_ROOT
    else
        local LOCAL_AOSP_HOMES=($(ls $LOCAL_AOSP_ROOT))
        chooseLocalAOSPHome "${LOCAL_AOSP_HOMES[@]}" || exit 1
    fi
}

function chooseLocalAOSPHome() {
    local AOSP_HOMES=("$@")
    if [ ${#AOSP_HOMES[@]} == 0 ]; then
        echo "\$LOCAL_AOSP_ROOT is not an AOSP root folder or does not contain subfolders"
        echo ""
        exit 1
    fi
    if [ ${#AOSP_HOMES[@]} == 1 ]; then
        LOCAL_AOSP_HOME=$LOCAL_AOSP_ROOT/"${AOSP_HOMES[0]}"
        echo "There is only one local AOSP subfolder available, using '$LOCAL_AOSP_HOME'"
    else
        echo ""
        echo "There are several local AOSP subfolders, please choose one:"
        for INDEX in "${!AOSP_HOMES[@]}"; do 
            let AOSP_HOME_INDEX=${INDEX}+1
            echo "$AOSP_HOME_INDEX. ${AOSP_HOMES[$INDEX]}"
        done
        echo ""
        echo "please choose an AOSP folder:"
        read INPUT
        if [[ $INPUT ]] && [ $INPUT -eq $INPUT 2>/dev/null ]; then
            if [ "$INPUT" -lt "1" ]; then
                echo "You can't choose zero, except you are Chuck Norris :)"
                echo ""
                exit 1
            fi
            if [ "$INPUT" -gt "${#AOSP_HOMES[@]}" ]; then
                echo "There are only ${#AOSP_HOMES[@]} folders to choose from."
                echo ""
                exit 1
            fi
            local INDEX="$((INPUT-1))" #its a valid number, so use the index
            LOCAL_AOSP_HOME=$LOCAL_AOSP_ROOT/"${AOSP_HOMES[$INDEX]}"
        else
            LOCAL_AOSP_HOME="$LOCAL_AOSP_ROOT/$INPUT"
        fi
        echo ""
    fi

    if [ -z $LOCAL_AOSP_HOME ]; then
        echo "Something's wrong, try again"
        echo ""
        exit 1
    fi
}

function setRemoteProductParent() {
    $SSH_CMD "test -e $REMOTE_AOSP_ROOT/build/envsetup.sh" > /dev/null
    if [ $? -eq 0 ]; then
        REMOTE_AOSP_HOME=$REMOTE_AOSP_ROOT
        LOCAL_AOSP_HOME=$LOCAL_AOSP_ROOT
    else
        local REMOTE_AOSP_HOMES=($($SSH_CMD ls $REMOTE_AOSP_ROOT))
        chooseRemoteAOSPHome "${REMOTE_AOSP_HOMES[@]}" || exit 1
        LOCAL_AOSP_HOME=$LOCAL_AOSP_ROOT/$(basename $REMOTE_AOSP_HOME)
    fi
    REMOTE_PRODUCT_PARENT_FOLDER="$REMOTE_AOSP_HOME/out/target/product"
    echo $REMOTE_PRODUCT_PARENT_FOLDER
    echo $LOCAL_AOSP_HOME
}

function chooseRemoteAOSPHome() {
    local AOSP_HOMES=("$@")
    if [ ${#AOSP_HOMES[@]} == 0 ]; then
        echo "\$REMOTE_AOSP_ROOT is not an AOSP root folder or does not contain subfolders"
        echo ""
        exit 1
    fi
    if [ ${#AOSP_HOMES[@]} == 1 ]; then
        REMOTE_AOSP_HOME=$REMOTE_AOSP_ROOT/"${AOSP_HOMES[0]}"
        echo "There is only one AOSP subfolder available at $SSH_HOST, using '$REMOTE_AOSP_HOME'"
    else
        echo ""
        echo "There are several AOSP subfolders at $SSH_HOST, please choose one:"
        for INDEX in "${!AOSP_HOMES[@]}"; do 
            let AOSP_HOME_INDEX=${INDEX}+1
            echo "$AOSP_HOME_INDEX. ${AOSP_HOMES[$INDEX]}"
        done
        echo ""
        echo "please choose an AOSP folder:"
        read INPUT
        if [[ $INPUT ]] && [ $INPUT -eq $INPUT 2>/dev/null ]; then
            if [ "$INPUT" -lt "1" ]; then
                echo "You can't choose zero, except you are Chuck Norris :)"
                echo ""
                exit 1
            fi
            if [ "$INPUT" -gt "${#AOSP_HOMES[@]}" ]; then
                echo "There are only ${#AOSP_HOMES[@]} folders to choose from."
                echo ""
                exit 1
            fi
            local INDEX="$((INPUT-1))" #its a valid number, so use the index
            REMOTE_AOSP_HOME=$REMOTE_AOSP_ROOT/"${AOSP_HOMES[$INDEX]}"
        else
            REMOTE_AOSP_HOME="$REMOTE_AOSP_ROOT/$INPUT"
        fi
        echo ""
    fi

    if [ -z $REMOTE_AOSP_HOME ]; then
        echo "Something's wrong, try again"
        echo ""
        exit 1
    fi
}

function chooseDevice() {
    local DEVICE_NAMES=("$@")
    if [ ${#DEVICE_NAMES[@]} == 0 ]; then
        echo "There are no devices available at $REMOTE_PRODUCT_PARENT_FOLDER"
        echo ""
        exit 1
    fi
    if [ ${#DEVICE_NAMES[@]} == 1 ]; then
        DEVICE_NAME="${DEVICE_NAMES[0]}"
        echo "There is only one device available, using '$DEVICE_NAME'"
    else
        echo ""
        echo "There are several devices, please choose one:"
        for INDEX in "${!DEVICE_NAMES[@]}"; do 
            let DEVICE_INDEX=${INDEX}+1
            echo "$DEVICE_INDEX. ${DEVICE_NAMES[$INDEX]}"
        done
        echo ""
        echo "please choose a device:"
        read INPUT
        if [[ $INPUT ]] && [ $INPUT -eq $INPUT 2>/dev/null ]; then
            if [ "$INPUT" -lt "1" ]; then
                echo "You can't choose zero, except you are Chuck Norris :)"
                echo ""
                exit 1
            fi
            if [ "$INPUT" -gt "${#DEVICE_NAMES[@]}" ]; then
                echo "There are only ${#DEVICE_NAMES[@]} devices to choose from."
                echo ""
                exit 1
            fi
            local INDEX="$((INPUT-1))" #its a valid number, so use the index
            DEVICE_NAME="${DEVICE_NAMES[$INDEX]}"
        else
            DEVICE_NAME=$INPUT
        fi
        echo ""
    fi

    if [ -z $DEVICE_NAME ]; then
        echo "Something's wrong, try again"
        echo ""
        exit 1
    fi
}

function getConnectedAndroidDevices() {
    local CONNECTED_FASTBOOT_DEVICES=($(fastboot devices | awk '{print $1}' | tr -d '[:blank:]'))
    local CONNECTED_ADB_DEVICES=($(adb devices | tail -n +2 | awk '{print $1}'))
    CONNECTED_DEVICES=()

    for DEVICE in "${CONNECTED_FASTBOOT_DEVICES[@]}"
    do
        CONNECTED_DEVICES+=$DEVICE
    done

    for DEVICE in "${CONNECTED_ADB_DEVICES[@]}"
    do
        CONNECTED_DEVICES+=$DEVICE
    done
}
