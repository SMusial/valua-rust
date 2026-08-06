group = "com.valuarust.valua_rust"
version = "1.0-SNAPSHOT"

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.5.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

android {
    compileSdk = 36
    namespace = "com.valuarust.rust_lib"

    defaultConfig {
        minSdk = 30
        targetSdk = 36
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}