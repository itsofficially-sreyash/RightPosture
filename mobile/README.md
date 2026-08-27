# Right Posture Mobile

Flutter Android app for the Right Posture on-device exercise-form demo.

## Prerequisites

- Flutter 3.48.0-0.3.pre / Dart 3.13.0 or a compatible newer SDK
- Android SDK 36 and JDK 17
- Android device with API 24 or newer and a camera
- USB debugging enabled for physical-device runs

## Setup and checks

Run commands from this `mobile/` directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

`flutter test` reports that no tests exist until domain logic is added in Iteration 03. This is expected during project baseline.

## Run on iQOO

1. Enable Developer options and USB debugging on the phone.
2. Connect by USB and accept the device authorization prompt.
3. Confirm detection with `adb devices -l` and `flutter devices`.
4. Start the app with `flutter run -d <device-id>`.
5. Grant camera access when requested.

The iQOO camera and pose-performance gate is tracked in `../execution/02_device_pose_spike.md`.

## Current scope

Android is the demo target. Web and desktop builds are not supported because ML Kit Pose Detection targets Android and iOS.
