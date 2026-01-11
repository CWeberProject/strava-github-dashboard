import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

// Load local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}

android {
    namespace = "com.stravawidget"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.stravawidget"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // Strava API credentials from local.properties
        buildConfigField("String", "STRAVA_CLIENT_ID", "\"${localProperties.getProperty("STRAVA_CLIENT_ID", "")}\"")
        buildConfigField("String", "STRAVA_CLIENT_SECRET", "\"${localProperties.getProperty("STRAVA_CLIENT_SECRET", "")}\"")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    // AndroidX Core
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")

    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")

    // Background work
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // Secure storage
    implementation("androidx.security:security-crypto:1.1.0-alpha06")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Browser for OAuth
    implementation("androidx.browser:browser:1.7.0")
}
