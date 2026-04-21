allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// NOTE: evaluationDependsOn(":app") removed — causes provider resolution
// failure with Firebase plugins on Java 21 + AGP 8.x.
// See docs/06-bypasses/android-firebase-bypasses.md

// Force compileSdk on all Android library subprojects (e.g. firebase_auth)
// so their provider has a value when Gradle resolves dependencies.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
            compileSdk = 35
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
