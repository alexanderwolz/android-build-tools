# Tool Collection for Whale Shark AAOS devices

![GitHub release (latest by date)](https://img.shields.io/github/v/release/alexanderwolz/android_device_whaleshark_tools)
![GitHub](https://img.shields.io/badge/aosp-14-orange)
![GitHub](https://img.shields.io/github/license/alexanderwolz/android_device_whaleshark_tools)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/alexanderwolz/android_device_whaleshark_tools)
![GitHub all releases](https://img.shields.io/github/downloads/alexanderwolz/android_device_whaleshark_tools/total?color=informational)


## 🧑‍💻 About

This repository contains tools to synch and flash Android images.

See also [android_device_whaleshark_tangorpro](https://github.com/alexanderwolz/android_device_whaleshark_tangorpro) for a Google Pixel Tablet based AAOS image.

And [android_device_whaleshark_emulator](https://github.com/alexanderwolz/android_device_whaleshark_emulator) for an ARM64-based AAOS Emulator image.


## 🪄 Environment

A ```.env```-file must be place in the root folder of this repository containing following properties (examples):

```
SSH_HOST="server.de"
SSH_USER="root"
SSH_PORT="22"
REMOTE_AOSP_HOME="/home/$USER/aosp"
LOCAL_AOSP_SYNCH="/home/$USER/aosp"
```

References to folders should be absolute.
You can also add ```SSH_KEY="~/.ssh/id_rsa"``` if your SSH is set up with key-pairs, otherwise it will ask for password.

## 🛠️ Scripts


### **bin/sync_remote_product_out.sh**


This script synchronizes the product files of a given target in ```$ANDROID_PRODUCT_OUT``` on a remote server to ```localhost```. *SSH* and *rsync* must be setup on both ends.

Use the script like this:

```
    bash bin/sync_remote_product_out.sh
    bash bin/sync_remote_product_out.sh $DEVICE_NAME
```

### **bin/flash_local_product_out.sh**


Use the script like this:

```
    bash bin/flash_local_product_out.sh -h
    bash bin/flash_local_product_out.sh $DEVICE_NAME
```

This script has been tested with images built for Google Pixel Tablet (tangorpro)


### **bin/sync_remote_emulator_images.sh**


This script synchronizes emulator image files of a given target in ```$ANDROID_PRODUCT_OUT``` on a remote server to ```localhost``` according to the ```ANDROID_SDK```-location. *SSH* and *rsync* must be setup on both ends.

Use the script like this:

```
    bash bin/sync_remote_emulator_images.sh
    bash bin/sync_remote_emulator_images.sh $DEVICE_NAME
```


## ⚙️ Android Virtual Device (AVD) configuration

### Setup

Copy the appropriate avd folder to ```$HOME/.android/avd```

```mkdir -p $HOME/.android/avd```

```cp -r avd/API34/whaleshark.avd $HOME/.android/avd/whaleshark.avd```

```cp avd/API34/whaleshark.ini $HOME/.android/avd/whaleshark.ini```


### Run the Emulator

Install the Android SDK and set ```$ANDROID_SDK_HOME```

Install the Android Emulator with version 33.1.23.0 or higher

Execute the Emulator: ```$ANDROID_SDK_HOME/emulator/emulator -avd whaleshark -show-kernel```


### Clear the Emulator

```bash bin/avd_wipe.sh```
