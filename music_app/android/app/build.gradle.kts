import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Firebase (google-services.json)
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { inputStream ->
        keystoreProperties.load(inputStream)
    }
}
// Muzee's upload keystore; key.properties may point elsewhere (storeFile).
val releaseKeystoreFile = file(keystoreProperties["storeFile"] as String? ?: "muzee_keystore")
val keyAliasValue = keystoreProperties["keyAlias"] as String?
val keyPasswordValue = keystoreProperties["keyPassword"] as String?
val storePasswordValue = keystoreProperties["storePassword"] as String?
val hasReleaseSigning =
    keystorePropertiesFile.exists() &&
    releaseKeystoreFile.exists() &&
    !keyAliasValue.isNullOrBlank() &&
    !keyPasswordValue.isNullOrBlank() &&
    !storePasswordValue.isNullOrBlank()

android {
    namespace = "up.nexstudio.muzee"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        // flutter_local_notifications (scheduled reminders) needs desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    defaultConfig {
        applicationId = "up.nexstudio.muzee"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Google sign-in (flutter_appauth) redirect.
        manifestPlaceholders["appAuthRedirectScheme"] =
            "com.googleusercontent.apps.812387227185-emvo8h4ins2k1fnkqbj0a99iq1lhatcs"

        // Patrol (E2E/native UI tests)
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    signingConfigs {
        create("release") {
            // Keep local/dev builds working when release keys are unavailable.
            if (hasReleaseSigning) {
                storeFile = releaseKeystoreFile
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
                storePassword = storePasswordValue
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }

    dependenciesInfo {
        // Disables dependency metadata when building APKs.
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles.
        includeInBundle = false
    }

    buildTypes {
        getByName("release") {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
        getByName("debug") {
            versionNameSuffix = " DEBUG"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

afterEvaluate {
    apply(from = "../no-build-id.gradle")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Patrol: runs each Dart test in a clean app process.
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
