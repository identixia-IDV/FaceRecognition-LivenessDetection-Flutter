group = "com.identixia.face_recognition_sdk"
version = "1.0-SNAPSHOT"


buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // AGP only — do not apply Kotlin Gradle Plugin (Built-in Kotlin / AGP 9+).
        classpath("com.android.tools.build:gradle:8.9.1")
    }
}


allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("${project.projectDir}/build/identixia-maven") }
    }
}


plugins {
    id("com.android.library")
}


android {
    namespace = "com.identixia.face_recognition_sdk"


    compileSdk = 36


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }


    defaultConfig {
        minSdk = 24
    }
}


// Built-in Kotlin (AGP 9+ / Flutter consumer) — no org.jetbrains.kotlin.android apply.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}


dependencies {
    implementation("androidx.exifinterface:exifinterface:1.3.7")


    // AGP forbids implementation(files("…aar")) on an Android library (plugin) module —
    // :face_recognition_sdk:bundleDebugAar would fail. Always consume the runtime via a
    // flat :libfacesdk artifact module (see example/android/libfacesdk).
    val libfacesdk = findProject(":libfacesdk")
    val bundledAar = file("libs/facerecognitionsdk.aar")
    when {
        libfacesdk != null -> implementation(project(":libfacesdk"))
        bundledAar.exists() ->
            throw GradleException(
                """
                Found android/libs/facerecognitionsdk.aar, but Flutter/AGP cannot link a
                local .aar with implementation(files(…)) from a plugin library module.


                Demo app: put the AAR in example/android/libfacesdk/facerecognitionsdk.aar
                (settings.gradle.kts already includes :libfacesdk).


                Your own app: copy example/android/libfacesdk/ into your Android project,
                place facerecognitionsdk.aar there, and add include(":libfacesdk") to
                settings.gradle — then depend on this plugin as usual.
                """.trimIndent()
            )
        else -> {
            val aar = file("build/identixia-fetch/facerecognitionsdk.aar")
            if (!aar.exists()) {
                aar.parentFile.mkdirs()
                val url = java.net.URI(
                    "https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Android/releases/download/v1.0.0/facerecognitionsdk-android.zip"
                ).toURL()
                try {
                    val zip = file("build/identixia-fetch/facerecognitionsdk-android.zip")
                    url.openStream().use { input -> zip.outputStream().use { input.copyTo(it) } }
                    copy {
                        from(zipTree(zip))
                        into(file("build/identixia-fetch"))
                    }
                } catch (e: Exception) {
                    throw GradleException(
                        """
                        Missing Face Recognition Android runtime (facerecognitionsdk.aar).

                        Demo: keep example/android/libfacesdk/facerecognitionsdk.aar
                        (settings.gradle.kts includes :libfacesdk).
                        Own app: apply
                        https://raw.githubusercontent.com/identixia-IDV/FaceRecognition-LivenessDetection-Android/v1.0.0/install.gradle
                        Download failed: ${e.message}
                        """.trimIndent()
                    )
                }
            }
            val resolved = fileTree("build/identixia-fetch").matching { include("**/facerecognitionsdk.aar") }.files.firstOrNull()
                ?: throw GradleException("facerecognitionsdk.aar was not in the v1.0.0 Release zip.")
            val maven = file("build/identixia-maven/com/identixia/facerecognitionsdk/1.0.0")
            maven.mkdirs()
            resolved.copyTo(maven.resolve("facerecognitionsdk-1.0.0.aar"), overwrite = true)
            maven.resolve("facerecognitionsdk-1.0.0.pom").writeText(
                """
                <project>
                  <modelVersion>4.0.0</modelVersion>
                  <groupId>com.identixia</groupId>
                  <artifactId>facerecognitionsdk</artifactId>
                  <version>1.0.0</version>
                  <packaging>aar</packaging>
                </project>
                """.trimIndent()
            )
            implementation("com.identixia:facerecognitionsdk:1.0.0")
        }
    }
}
