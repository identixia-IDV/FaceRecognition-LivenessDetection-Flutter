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


// AGP forbids implementation(files("…aar")) on an Android library (plugin) module —
// :face_recognition_sdk:bundleDebugAar would fail. Always consume the runtime via a
// flat :libfacesdk artifact module (see example/android/libfacesdk).
val libfacesdk = findProject(":libfacesdk")

dependencies {
    implementation("androidx.exifinterface:exifinterface:1.3.7")

    val bundledAar = file("libs/facerecognitionsdk.aar")
    fun useLocalMavenAar(source: java.io.File) {
        val maven = file("build/identixia-maven/com/identixia/facerecognitionsdk/1.0.0")
        maven.mkdirs()
        source.copyTo(maven.resolve("facerecognitionsdk-1.0.0.aar"), overwrite = true)
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

    when {
        libfacesdk != null -> implementation(project(":libfacesdk"))
        bundledAar.exists() -> useLocalMavenAar(bundledAar)
        else -> {
            val aar = file("build/identixia-fetch/facerecognitionsdk.aar")
            if (!aar.exists()) {
                aar.parentFile.mkdirs()
                val zip = file("build/identixia-fetch/facerecognitionsdk-android.zip")
                try {
                    ant.invokeMethod(
                        "get",
                        mapOf(
                            "src" to "https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-Android/releases/latest/download/facerecognitionsdk-android.zip",
                            "dest" to zip.absolutePath,
                        ),
                    )
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
                ?: throw GradleException("facerecognitionsdk.aar was not in the Latest Release zip.")
            useLocalMavenAar(resolved)
        }
    }
}

// Engine packs (.xdb) are not inside the AAR — same as Android install.gradle.
// Stage them as assets/facerecognitionsdk/ so every consumer APK (example, *-Test) can init.
fun File.hasXdb(): Boolean =
    isDirectory && listFiles()?.any { it.isFile && it.name.endsWith(".xdb") } == true

val faceDbSrc: File? =
    sequenceOf(
        libfacesdk?.let { File(it.projectDir, "databases") },
        file("libs/databases"),
        file("build/identixia-fetch/databases"),
    ).filterNotNull().firstOrNull { it.hasXdb() }

if (faceDbSrc != null) {
    val packsOut = file("build/generated/identixiaAssets")
    val dest = packsOut.resolve("facerecognitionsdk")
    dest.mkdirs()
    faceDbSrc.listFiles()
        ?.filter { it.isFile && it.name.endsWith(".xdb") }
        ?.forEach { src ->
            val out = dest.resolve(src.name)
            if (!out.exists() || out.length() != src.length()) {
                src.copyTo(out, overwrite = true)
            }
        }
    android.sourceSets.getByName("main").assets.srcDir(packsOut)
}
