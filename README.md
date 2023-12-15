# Tool Collection for AOSP and AAOS builds

![GitHub release (latest by date)](https://img.shields.io/github/v/release/alexanderwolz/android-build-tools)
![GitHub](https://img.shields.io/github/license/alexanderwolz/android-build-tools)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/alexanderwolz/android-build-tools)
![GitHub all releases](https://img.shields.io/github/downloads/alexanderwolz/android-build-tools/total?color=informational)


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


### **bin/create_local_product_package.sh**

This scripts creates a zip package that can be flashed to Android devices. Use the script like this:

```
    bash bin/create_local_product_package.sh
    bash bin/create_local_product_package.sh $DEVICE_NAME
```

### **bin/flash_local_product_out.sh**

This scripts flashes all existing images from ```ANDROID_PRODUCT_OUT``` to a connected Android device.

```
    bash bin/flash_local_product_out.sh
    bash bin/flash_local_product_out.sh $DEVICE_NAME
```


### **bin/flash_product_zip.sh**

This scripts flashes a given product zip to a connected Android device.

```
    bash bin/flash_product_zip.sh $ZIP_FILE
```


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
