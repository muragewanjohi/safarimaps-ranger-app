import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun readGoogleMapsApiKey(): String {
    val secretsProperties = Properties()
    val secretsFile = rootProject.file("secrets.properties")
    if (secretsFile.exists()) {
        secretsFile.inputStream().use { stream ->
            secretsProperties.load(stream)
        }
    }

    secretsProperties.getProperty("GOOGLE_MAPS_ANDROID_API_KEY")
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?.let { return it }

    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { stream ->
            localProperties.load(stream)
        }
    }

    localProperties.getProperty("GOOGLE_MAPS_ANDROID_API_KEY")
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?.let { return it }

    val envFile = rootProject.file("../.env")
    if (envFile.exists()) {
        envFile.readLines().forEach { line ->
            val trimmed = line.trim()
            if (trimmed.startsWith("GOOGLE_MAPS_ANDROID_API_KEY=")) {
                return trimmed
                    .removePrefix("GOOGLE_MAPS_ANDROID_API_KEY=")
                    .trim()
                    .removeSurrounding("\"")
                    .removeSurrounding("'")
            }
        }
    }

    return ""
}

val googleMapsApiKey = readGoogleMapsApiKey()
if (googleMapsApiKey.isEmpty()) {
    logger.warn(
        "GOOGLE_MAPS_ANDROID_API_KEY is empty. " +
            "Add it to android/secrets.properties to enable Google Maps.",
    )
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { stream ->
        keystoreProperties.load(stream)
    }
}

android {
    namespace = "com.safarimap.gamewarden"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.safarimap.gamewarden"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_ANDROID_API_KEY"] = googleMapsApiKey
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "android/key.properties not found. Release builds will use debug signing. " +
                        "Configure key.properties before uploading to Google Play.",
                )
                signingConfig = signingConfigs.getByName("debug")
            }
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
