allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/**
 * 🔥 Firebase / Google Services support (IMPORTANT)
 * This ensures Firebase plugin works in Kotlin DSL projects
 */
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.google.gms:google-services:4.4.4")
    }
}

/**
 * Build directory configuration (Flutter default)
 */
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()

rootProject.layout.buildDirectory.value(newBuildDir)

/**
 * Subproject build directory handling
 */
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

/**
 * Clean task
 */
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}
