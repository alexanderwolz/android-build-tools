# Tool Collection for AOSP device 'Catfish'

See also https://github.com/alexanderwolz/android_device_catfish

## AVD

Customize the absolute path (line 2) in ```avd/catfish.ini```

Copy or SymLink the avd to ```$HOME/.android/avd```

```mkdir -p $HOME/.android/avd```

```ln -sf avd/catfish.avd $HOME/.android/avd/catfish.avd```

```ln -sf avd/catfish.ini $HOME/.android/avd/catfish.ini```

## Run the Emulator*

Install the Android SDK and set ```$ANDROID_HOME```

Install the Android Emulator with version 32.1.5.0 or higher

Execute the Emulator: ```$ANDROID_HOME/emulator/emulator -avd catfish -show-kernel```

\* Catfish currently only runs on Emulators for ARM-based hosts (e.g. MacBook Pro 2021)

## Clear the Emulator

```bash bin/clean_avd.sh```

## Sync built files from build-server to localhost

Create ```.env``` file in ```bin``` and adopt variables listed in ```bin/synch_target.sh```

Execute script via ```bash bin/synch_target.sh catfish```
