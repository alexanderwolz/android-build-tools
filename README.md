# Tool Collection for AOSP device 'Catfish'

See also https://github.com/alexanderwolz/android_device_catfish

## AVD

Copy or SymLink the avds to ```$HOME/.android/avd```

```mkdir -p $HOME/.android/avd```

```ln -sf avd/catfish.avd $HOME/.android/avd/catfish.avd```

```ln -sf avd/catfish.ini $HOME/.android/avd/catfish.ini```

## Run the Emulator*

Install the Android SDK with Android Studio and set ```$ANDROID_HOME```

Execute the Emulator: ```$ANDROID_HOME/emulator/emulator -avd catfish -show-kernel```


\* Currently only runs on Emulator for ARM-based hosts (e.g. MacBook Pro 2021)
