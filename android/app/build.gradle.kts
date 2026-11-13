import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release upload key. android/key.properties is never committed; when it is
// absent (fresh checkout, CI-less local builds) release builds fall back to the
// debug key so `flutter run --release` still works on a test phone.
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keyPropertiesFile.exists()
if (hasReleaseKey) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "app.docnook.reader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.docnook.reader"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ML Kit's and Tesseract's libraries ask for uncompressed native code,
    // which roughly quadruples the APK. Compress it: the app starts only a
    // little slower once, at install, and downloads are much smaller.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    flavorDimensions += "distribution"
    productFlavors {
        // Google Play build (AAB).
        create("play") {
            dimension = "distribution"
        }
        // Direct APK build. A different id lets both installs coexist, because
        // Play re-signs the Play build with Google's app-signing key.
        create("direct") {
            dimension = "distribution"
            applicationIdSuffix = ".direct"
        }
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // FileProvider for sharing outputs and "Open with another app".
    implementation("androidx.core:core-ktx:1.16.0")
    // Tesseract OCR for phones without Google Play services; direct APK only.
    "directImplementation"("cz.adaptech.tesseract4android:tesseract4android:4.9.0")
}
