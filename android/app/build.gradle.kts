plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.euroside.app"

    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility =
            JavaVersion.VERSION_11

        targetCompatibility =
            JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget =
            JavaVersion.VERSION_11.toString()
    }

    defaultConfig {

        applicationId =
            "com.euroside.app"

        minSdk = 24

        targetSdk =
            flutter.targetSdkVersion

        versionCode =
            flutter.versionCode

        versionName =
            flutter.versionName
    }

    buildTypes {
        release {

            signingConfig =
                signingConfigs.getByName(
                    "debug"
                )
        }
    }
}

flutter {
    source = "../.."
}