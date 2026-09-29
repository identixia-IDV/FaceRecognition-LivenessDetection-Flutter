# Android runtime

The example uses `example/android/libfacesdk/` (`settings.gradle.kts` includes `:libfacesdk`). Do not also put `facerecognitionsdk.aar` in this `android/libs/` folder: Flutter cannot link a local AAR with `implementation(files(…))` from the plugin module.

Your app depends on `face_recognition_sdk` at tag `v1.0.0`. The plugin downloads the Android GitHub Release when `:libfacesdk` is not in the app.
