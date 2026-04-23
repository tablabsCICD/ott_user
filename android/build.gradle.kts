import com.android.build.gradle.LibraryExtension

plugins {
  // ...

  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.4.4" apply false

}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.findByType(LibraryExtension::class.java)?.let { androidExt ->
            if (androidExt.namespace == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifestText = manifestFile.readText()
                    val packageName =
                        Regex("""package\s*=\s*"([^"]+)"""")
                            .find(manifestText)
                            ?.groupValues
                            ?.getOrNull(1)

                    if (!packageName.isNullOrBlank()) {
                        androidExt.namespace = packageName
                    }
                }
            }
        }
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
