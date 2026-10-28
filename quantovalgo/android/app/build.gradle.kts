import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chiave di firma personale (android/key.properties + app/quantovalgo.jks).
// I due file NON vanno su GitHub (sono già in .gitignore). Se mancano,
// la build usa la chiave di debug e il login Google non funzionerà.
val proprietaChiave = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val haChiave = proprietaChiave.containsKey("storeFile")

android {
    namespace = "it.francesco.quantovalgo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "it.francesco.quantovalgo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (haChiave) {
            create("personale") {
                storeFile = file(proprietaChiave.getProperty("storeFile"))
                storePassword = proprietaChiave.getProperty("storePassword")
                keyAlias = proprietaChiave.getProperty("keyAlias")
                keyPassword = proprietaChiave.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        // Stessa chiave per debug e release: un'unica impronta SHA-1 da registrare.
        val firma = if (haChiave) signingConfigs.getByName("personale") else signingConfigs.getByName("debug")
        debug { signingConfig = firma }
        release { signingConfig = firma }
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
