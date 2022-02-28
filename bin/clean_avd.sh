#!/bin/bash

AVD_FOLDER="$HOME/.android/avd/catfish.avd"

pushd "$AVD_FOLDER" >/dev/null || exit 1
echo "cleaning $AVD_FOLDER"
find . -mindepth 1 ! -name "config.ini" -delete
echo "Done"
popd >/dev/null