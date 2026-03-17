# apkbuild-termux
Build Android APK directly from your phone using Termux - No PC required!

## Requirements
- Termux
- proot-distro (Ubuntu)
- Android SDK 33
- Java 17
- Gradle 7.5

## Installation
Run this once to setup the full environment:
bash setup.sh

## Usage
apkbuild new myapp
apkbuild build myapp

## Project Structure
/root/projectname/
  settings.gradle
  build.gradle
  gradlew
  gradle/
  app/
    build.gradle
    src/main/
      AndroidManifest.xml
      java/com/package/
      res/layout/
      res/values/
      res/drawable/
      res/raw/

## Important Notes for AI
- Write large files using Python scripts not cat EOF
- Emoji in Java use Unicode like U+1F430 not direct emoji
- Do not put emoji directly in XML files
- Remove android:allCaps from XML it causes errors
- AAPT2 was replaced with ARM64 version from AndroidIDEOfficial
- minSdk must be 23 or higher
- Build command: cd /root/project && ./gradlew assembleDebug --no-daemon
- APK output: app/build/outputs/apk/debug/app-debug.apk
- Copy to Downloads: cp app-debug.apk /sdcard/Download/name.apk

## How it works
Sets up complete Android environment inside Ubuntu on Termux.
Uses Gradle 7.5 and Android SDK 33 to build real APK files.

## Notes
- First setup takes 30 minutes
- Builds take 2 minutes
- APK saved to Downloads
- No root required
- Tested on ARM64 devices

## Credits
Built with love from a phone using Termux
