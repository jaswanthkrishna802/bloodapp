import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// 🔥 Firebase + Google services setup
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 🔥 REQUIRED for Firebase
        classpath("com.google.gms:google-services:4.4.0")
    }
}

// 📦 Repositories for all modules
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔧 Custom build directory (Flutter optimization)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

// 🔧 Apply same build directory to subprojects
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🔧 Ensure :app builds first
subprojects {
    project.evaluationDependsOn(":app")
}

// 🧹 Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}