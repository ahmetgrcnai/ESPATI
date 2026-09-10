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
subprojects {
    project.evaluationDependsOn(":app")
}

// Several plugins still declare Java 8 sourceCompatibility/targetCompatibility in
// their own build.gradle, which JDK 21 flags as "obsolete and will be removed in a
// future release". Forcing every plugin module onto a single Java/Kotlin version is
// too fragile — plugins pin different (and mutually consistent) Java/Kotlin target
// pairs, and overriding just one side breaks that pairing (e.g. Java 11 + Kotlin 17
// triggers a hard "Inconsistent JVM Target Compatibility" build failure). Since this
// is only a diagnostic, suppress the -options lint category instead, exactly as the
// javac warning itself suggests ("use -Xlint:-options").
subprojects {
    tasks.withType(JavaCompile::class.java).configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
