plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    // Unique from AAR package com.identixia.facerecognitionsdk (AGP namespace clash).
    // License binds to applicationId below, not this namespace.
    namespace = "com.identixia.facerecognition.example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion


    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    defaultConfig {
        applicationId = "com.identixia.facerecognitionsdk"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}


kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}


flutter {
    source = "../.."
}
