plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // 🔥 ADD THIS LINE FOR FIREBASE
    id("com.google.gms.google-services")
}

android {
    namespace = "com.zacharia.noticeboard_nit"
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
        applicationId = "com.zacharia.noticeboard_nit"

        // 🔥 IMPORTANT FOR FIREBASE
        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}



dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:34.12.0"))


  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
 

  // https://firebase.google.com/docs/android/setup#available-libraries





    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))

    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")

}
