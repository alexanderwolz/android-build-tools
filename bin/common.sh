#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE_NAME=".env"
ENV_FILE="$PARENT_DIR/$ENV_FILE_NAME"

# Properties needed from env file in root folder:
# 	SSH_HOST="server.de"
# 	SSH_USER="root"
# 	SSH_PORT="22"
# 	SSH_KEY="~/.ssh/id_rsa"
# 	REMOTE_AOSP_HOME="/home/$USER/aosp" - must be absolute
# 	LOCAL_AOSP_SYNCH="/home/$USER/aosp" - must be absolute

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

if [ -z $REMOTE_AOSP_HOME ]; then
	echo "Please set '\$REMOTE_AOSP_HOME' in $ENV_FILE"
    echo ""
	exit 1
fi

if [ -z $LOCAL_AOSP_SYNCH ]; then
	echo "Please set '\$LOCAL_AOSP_SYNCH' in $ENV_FILE"
    echo ""
	exit 1
fi

REMOTE="$SSH_USER@$SSH_HOST"
REMOTE_PRODUCT_PARENT_FOLDER="$REMOTE_AOSP_HOME/out/target/product"

if [ ! -z $SSH_KEY ]; then
	SSH_OPTS+=" -i $SSH_KEY"
fi

if [ ! -z $SSH_PORT ]; then
	SSH_OPTS+=" -p $SSH_PORT"
fi

SSH_CMD="ssh $SSH_OPTS"
SSH_OPTS="ssh$SSH_OPTS"

function chooseDevice() {
    local DEVICE_NAMES=("$@")
    if [ ${#DEVICE_NAMES[@]} == 0 ]; then
        echo "There are no devices available at $REMOTE_PRODUCT_PARENT_FOLDER"
        echo ""
        exit 1
    fi
    if [ ${#DEVICE_NAMES[@]} == 1 ]; then
        DEVICE_NAME="${DEVICE_NAMES[0]}"
        echo "There is only one device availabe, using '$DEVICE_NAME'"
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
