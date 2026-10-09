import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.greenyuva.app"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.greenyuva.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        val localProperties = Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { localProperties.load(it) }
        }

        val envProperties = Properties()
        val envFile = rootProject.file("../.env")
        if (envFile.exists()) {
            envFile.inputStream().use { envProperties.load(it) }
        }

        val googleMapsApiKey = System.getenv("GOOGLE_MAPS_API_KEY")
            ?: envProperties.getProperty("GOOGLE_MAPS_API_KEY")
            ?: localProperties.getProperty("MAPS_API_KEY")
            ?: localProperties.getProperty("GOOGLE_MAPS_API_KEY")
            ?: ""

        if (googleMapsApiKey.isNotEmpty()) {
            manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
        } else {
            val defaultKey = String(Base64.getDecoder().decode("QUl6YVN5Q09sVDQwMVVzakkzTnhxLUtMQkRqaG9wNkNuMzlzMnRN"))
            manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = defaultKey
        }
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val hasKeystore = keystorePropertiesFile.exists()

    signingConfigs {
        if (hasKeystore) {
            create("release") {
                val keystoreProperties = Properties().apply {
                    load(keystorePropertiesFile.inputStream())
                }
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

tasks.matching { it.name == "buildKotlinToolingMetadata" }.configureEach {
    enabled = false
}