allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate { project ->
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension != null) {
            try {
                val getNamespaceMethod = androidExtension.javaClass.getMethod("getNamespace")
                val namespaceValue = getNamespaceMethod.invoke(androidExtension)
                if (namespaceValue == null) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestText = manifestFile.readText()
                        val packageRegex = Regex("package=\"([^\"]+)\"")
                        val match = packageRegex.find(manifestText)
                        if (match != null) {
                            val setNamespaceMethod = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
                            setNamespaceMethod.invoke(androidExtension, match.groupValues[1])
                            println("[namespace-patch] Set namespace for ${project.name}: ${match.groupValues[1]}")
                        } else {
                            val fallbackNamespace = "com.example.${project.name.replace("-", "_").replace(".", "_")}"
                            val setNamespaceMethod = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
                            setNamespaceMethod.invoke(androidExtension, fallbackNamespace)
                            println("[namespace-patch] Set fallback namespace for ${project.name}: $fallbackNamespace")
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore for extensions without namespace support
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
