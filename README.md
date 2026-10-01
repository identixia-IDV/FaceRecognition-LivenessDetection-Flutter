<div align="center">
<img alt="Identixia" src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/brand/logo.png" width="320"/>

<a href="https://identixia.com"><img src="https://img.shields.io/badge/Website-0F766E?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Website" /></a>
<a href="https://docs.identixia.com"><img src="https://img.shields.io/badge/Docs-0F766E?style=for-the-badge&logo=gitbook&logoColor=white" alt="Docs" /></a>
<a href="https://huggingface.co/Identixia"><img src="https://img.shields.io/badge/HuggingFace-FFD21E?style=for-the-badge&logo=huggingface&logoColor=black" alt="Hugging Face" /></a>
<a href="https://hub.docker.com/u/identixia"><img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker Hub" /></a>
<a href="https://playground.identixia.com/"><img src="https://img.shields.io/badge/Playground-0F766E?style=for-the-badge&logo=cloudplayground&logoColor=white" alt="Playground" /></a>
</div>

<div align="center">

# <img src="https://cdn.simpleicons.org/flutter/02569B" width="32" height="32" alt="" /> Identixia Face Recognition — Flutter

</div>


**On-device face recognition SDK** plugin: enroll, **1:N identification**, guided capture, attributes, and optional **passive face liveness**. Face template matching runs on the device — **no** biometric frames uploaded to Identixia cloud. Ideal for KYC selfie checks and private galleries inside your mobile app.

Package: `face_recognition_sdk`. Demo modes: **Enroll · Identify · Capture · Attribute**.

<p><img src="https://img.shields.io/badge/On-device-0F766E?style=flat-square" alt="On-device" /> <img src="https://img.shields.io/badge/1%3AN%20identification-0F766E?style=flat-square" alt="1%3AN%20identification" /> <img src="https://img.shields.io/badge/Passive%20liveness-0F766E?style=flat-square" alt="Passive%20liveness" /> <img src="https://img.shields.io/badge/Android%20%2B%20iOS-0F766E?style=flat-square" alt="Android%20%2B%20iOS" /> <img src="https://img.shields.io/badge/Plugin-5A6573?style=flat-square" alt="Plugin" /></p>


---

## <img src="https://api.iconify.design/lucide/clipboard-list.svg?color=%230F766E" width="24" height="24" alt="" /> Basics

Read this once before cloning. Plugin demos ship a **bundled license** for the sample Android / iOS ids. Production apps need a new key. [Initial commands](#-initial-commands) lists clone → place runtime → run → activate options.

| Topic | Basic information |
| --- | --- |
| **Product** | On-device **face recognition** Flutter plugin |
| **Modes** | Enroll · Identify (1:N) · Capture · Attribute |
| **API** | Detect · templates · identify · optional passive liveness |
| **Runtime** | Local example engines, or the `v1.0.0` GitHub Release when missing |
| **Demo id** | `com.identixia.facerecognitionsdk` / `com.identixia.facerecognitionsdk.app` |
| **Tools** | Flutter 3.44+ · physical arm64 Android / iPhone |
| **UI** | Four demo modes after Ready · package kit `FaceCapture` |
| **Privacy** | Templates stay on device — no Identixia cloud |


---

## <img src="https://api.iconify.design/lucide/terminal.svg?color=%230F766E" width="24" height="24" alt="" /> Initial commands

Must-know path for the sample / example app.

### <img src="https://img.shields.io/badge/-1-0F766E?style=for-the-badge" alt="" /> Clone and run

```bash
git clone https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Flutter.git
cd FaceRecognition-LivenessDetection-Flutter
dart run tool/bootstrap.dart
cd example && flutter run
```

### <img src="https://img.shields.io/badge/-2-0F766E?style=for-the-badge" alt="" /> Activate / license

Please [contact us](#-contact) to get a license for your own app. The sample already includes a demo license for its application id.


### <img src="https://img.shields.io/badge/-3-0F766E?style=for-the-badge" alt="" /> First capture

Wait until Home = **Ready**, then Enroll / Identify / Capture / Attribute.


---

## <img src="https://api.iconify.design/lucide/list-checks.svg?color=%230F766E" width="24" height="24" alt="" /> What you get

| Capability | What it does |
| --- | --- |
| <img src="https://api.iconify.design/lucide/user-plus.svg?color=%230F766E" width="16" height="16" alt="" /> Enroll | Capture face templates into an on-device gallery |
| <img src="https://api.iconify.design/lucide/users.svg?color=%230F766E" width="16" height="16" alt="" /> Identify (1:N) | Match a live or still face against enrolled templates |
| <img src="https://api.iconify.design/lucide/aperture.svg?color=%230F766E" width="16" height="16" alt="" /> Capture | Guided still capture with quality feedback |
| <img src="https://api.iconify.design/lucide/sliders.svg?color=%230F766E" width="16" height="16" alt="" /> Attribute | Age / gender / expression-style attributes when enabled |
| <img src="https://api.iconify.design/lucide/shield.svg?color=%230F766E" width="16" height="16" alt="" /> Passive liveness | Optional face PAD (and deepfake checks when licensed on server) |
| <img src="https://api.iconify.design/lucide/fingerprint.svg?color=%230F766E" width="16" height="16" alt="" /> Templates | Compact face template extraction + similarity / matching |


---

## <img src="https://api.iconify.design/lucide/app-window.svg?color=%230F766E" width="24" height="24" alt="" /> Demo modes

| Mode | What to try |
| --- | --- |
| **Enroll** | Create an on-device gallery entry (template + thumbnail) |
| **Identify** | Live 1:N search against enrolled faces |
| **Capture** | Guided still capture with quality feedback |
| **Attribute** | Attribute scores when enabled |

---

## <img src="https://api.iconify.design/lucide/pc-case.svg?color=%230F766E" width="24" height="24" alt="" /> Requirements

| | |
| --- | --- |
| Devices | Physical **arm64** Android and/or **iPhone** |
| Package | `face_recognition_sdk` |
| Runtimes | Local example engines, or the `v1.0.0` GitHub Release when they are missing |

---

## <img src="https://api.iconify.design/lucide/package.svg?color=%230F766E" width="24" height="24" alt="" /> Install

The example builds with native runtimes already in the clone when present. Gradle / CocoaPods download the `v1.0.0` GitHub Releases only when a file is missing.

- AAR → `example/android/libfacesdk/facerecognitionsdk.aar`
- iOS → `ios/Frameworks/` (`facerecognitionsdk`, `FaceRecognitionEngine`, `onnxruntime`)

Customer apps depend on `face_recognition_sdk` from this repo at tag `v1.0.0` (Flutter: git dependency; React Native / Ionic: npm / github package). Do **not** use a monorepo `path:` dependency in shipping apps.

Android: keep `packaging { jniLibs { useLegacyPackaging = true } }` so `libFaceRecognitionEngine.so` is extracted for `nativeInitEngine`.

---

## <img src="https://api.iconify.design/lucide/rocket.svg?color=%230F766E" width="24" height="24" alt="" /> Run

```bash
git clone https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Flutter.git
cd FaceRecognition-LivenessDetection-Flutter
dart run tool/bootstrap.dart
cd example && flutter run   # physical device
```


After Ready, open **Enroll · Identify · Capture · Attribute**.

---

## <img src="https://api.iconify.design/lucide/key-round.svg?color=%230F766E" width="24" height="24" alt="" /> License

Demo ids: Android `com.identixia.facerecognitionsdk` · iOS `com.identixia.facerecognitionsdk.app`.

The code below shows how to use the license:

[https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Flutter/blob/d4d3171f41360c09888322893a789b70ae973fd8/example/lib/core/constants/license.dart#L6-L14](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Flutter/blob/d4d3171f41360c09888322893a789b70ae973fd8/example/lib/core/constants/license.dart#L6-L14)

[https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Flutter/blob/d4d3171f41360c09888322893a789b70ae973fd8/example/lib/services/sdk_service.dart#L28-L39](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Flutter/blob/d4d3171f41360c09888322893a789b70ae973fd8/example/lib/services/sdk_service.dart#L28-L39)

Capabilities: face recognition (detect / templates / match) and/or passive face liveness. Please [contact us](#-contact) to get a license for **your own app**.

---

## <img src="https://api.iconify.design/lucide/puzzle.svg?color=%230F766E" width="24" height="24" alt="" /> Use in your app

Depend on `face_recognition_sdk` via git (`ref: v1.0.0`), set Android `useLegacyPackaging = true`, then use `FaceCapture` / activate → init → detect / template / identify.

Typical flow: depend on `face_recognition_sdk` at `v1.0.0` → ship / download native runtimes → activate → init → enroll / identify / capture. Prefer package kits (`FaceCapture`, …) over reinventing the camera UI. Keep demo ids only while using sample licenses.

| Step | Detail |
| --- | --- |
| 1 | Depend on `face_recognition_sdk` at tag `v1.0.0` (standalone clone — no monorepo `path:`) |
| 2 | Keep or download Android AAR + iOS frameworks (`v1.0.0` Release) |
| 3 | Activate → init on a physical device (`useLegacyPackaging = true` on Android) |
| 4 | Wire Enroll / Identify (1:N) / Capture / Attribute (+ liveness if licensed) |

---

## <img src="https://api.iconify.design/lucide/images.svg?color=%230F766E" width="24" height="24" alt="" /> Screenshots

<p align="center">
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/home.png" width="160" alt="Face recognition home — detect, attribute, quality, landmarks, match, liveness, enroll, identity" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/capture.png" width="160" alt="Identity camera — move closer" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/enroll.png" width="160" alt="Enroll result" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/identify.png" width="160" alt="1:N identify result" />
</p>
<p align="center">
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/detect.png" width="160" alt="Face detect result" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/attribute.png" width="160" alt="Face attribute result" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/attribute-quality.png" width="160" alt="Image quality result" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/landmarks.png" width="160" alt="68-point landmarks" />
</p>
<p align="center">
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/match.png" width="160" alt="1:1 match result" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/attribute-liveness.png" width="160" alt="Liveness result" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/settings.png" width="160" alt="Settings — camera, landmarks, thresholds" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/face-recognition/android/about.png" width="160" alt="About, license, and application id" />
</p>

---

## <img src="https://api.iconify.design/lucide/layers.svg?color=%230F766E" width="24" height="24" alt="" /> Platforms

| | Platform | Repo |
| --- | --- | --- |
| <img src="https://cdn.simpleicons.org/android/3DDC84" width="18" height="18" alt="" /> | Android | [FaceRecognition-LivenessDetection-Android](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Android) |
| <img src="https://cdn.simpleicons.org/apple/000000" width="18" height="18" alt="" /> | iOS | [FaceRecognition-LivenessDetection-iOS](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-iOS) |
| <img src="https://cdn.simpleicons.org/flutter/02569B" width="18" height="18" alt="" /> | Flutter | [FaceRecognition-LivenessDetection-Flutter](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Flutter) |
| <img src="https://cdn.simpleicons.org/react/61DAFB" width="18" height="18" alt="" /> | React Native | [FaceRecognition-LivenessDetection-React-Native](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-React-Native) |
| <img src="https://cdn.simpleicons.org/ionic/3880FF" width="18" height="18" alt="" /> | Ionic Capacitor | [FaceRecognition-LivenessDetection-Ionic-Capacitor](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Ionic-Capacitor) |
| <img src="https://cdn.simpleicons.org/apachecordova/E8E8E8" width="18" height="18" alt="" /> | Ionic Cordova | [FaceRecognition-LivenessDetection-Ionic-Cordova](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Ionic-Cordova) |
| <img src="https://cdn.simpleicons.org/windows/0078D4" width="18" height="18" alt="" /> | Windows | [FaceRecognition-LivenessDetection-Windows](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Windows) |
| <img src="https://cdn.simpleicons.org/docker/2496ED" width="18" height="18" alt="" /> | Linux / Docker | [FaceRecognition-LivenessDetection-Docker](https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Docker) |


---

## <img src="https://api.iconify.design/lucide/mail.svg?color=%230F766E" width="24" height="24" alt="" /> Contact

<div align="center">

<a href="mailto:contact@identixia.com"><img alt="Email contact@identixia.com" src="https://img.shields.io/badge/Email-contact%40identixia.com-0F766E?style=for-the-badge&logo=gmail&logoColor=white" /></a>
<a href="https://wa.me/17018854218"><img alt="WhatsApp +1 (701) 885-4218" src="https://img.shields.io/badge/WhatsApp-%2B1_(701)_885--4218-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" /></a>
<a href="https://t.me/identixia"><img alt="Telegram @identixia" src="https://img.shields.io/badge/Telegram-%40identixia-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" /></a>

</div>
