plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.motohead.motohead_app"
    compileSdk = 36  // Android 16 (required by plugins)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.motohead.motohead_app"
        minSdk = flutter.minSdkVersion  // Android 5.0 Lollipop
        targetSdk = 35  // Android 15
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signing config for consistent APK updates.
    // Uses debug keystore by default; CI overrides via environment variables.
    val keystorePath = System.getenv("KEYSTORE_PATH")
    val keystorePass = System.getenv("KEYSTORE_PASSWORD")
    val keyAliasVal = System.getenv("KEY_ALIAS")
    val keyPass = System.getenv("KEY_PASSWORD")

    if (keystorePath != null && file(keystorePath).exists()) {
        signingConfigs {
            create("release") {
                storeFile = file(keystorePath)
                storePassword = keystorePass
                keyAlias = keyAliasVal
                keyPassword = keyPass
            }
        }
    }

    buildTypes {
        debug {
            // Use debug signing for local development
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // Use release keystore if available, otherwise debug keys
            signingConfig = if (keystorePath != null && file(keystorePath).exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
