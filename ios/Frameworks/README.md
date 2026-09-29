# iOS frameworks

This folder holds `facerecognitionsdk.framework`, `FaceRecognitionEngine.framework`, and `onnxruntime.framework` when they are already in the clone. CocoaPods downloads the `v1.0.0` iOS GitHub Release only when none of them are here.

From the plugin root, `dart run tool/bootstrap.dart` checks that the frameworks are present. iOS builds need macOS and Xcode.
