<div align="center">

# iOS example host

</div>


Requirements: **Flutter 3.44+**, **macOS + Xcode**, physical device recommended.


Demo license bundle id: **`com.identixia.facerecognitionsdk.app`**
(Android demo `applicationId` is `com.identixia.facerecognitionsdk` — different on purpose.)


1. The plugin uses the three frameworks in `ios/Frameworks/` (not `example/ios/`) when they are already there:


   ```text
   FaceRecognition-LivenessDetection-Flutter/ios/Frameworks/
   ├── facerecognitionsdk.framework
   ├── FaceRecognitionEngine.framework
   └── onnxruntime.framework
   ```


2. From the **plugin root**: `dart run tool/bootstrap.dart` (should print `ok:` for each framework)
3. `cd example && flutter pub get`
4. `cd ios && pod install`
5. Open `Runner.xcworkspace` and set **Team** / signing


Camera / photos: `Podfile` `post_install` sets `PERMISSION_CAMERA=1` and
`PERMISSION_PHOTOS=1` for `permission_handler`.
