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

\* Catfish currently only runs on Emulators for ARM-based hosts (e.g. MacBook Pro 2021)

## Clear the Emulator

```bash bin/clean_avd.sh```

## Sync built files from build-server to localhost

Create ```.env``` file in ```bin``` and adopt variables listed in ```bin/synch_target.sh```

```bash bin/synch_target.sh catfish```
