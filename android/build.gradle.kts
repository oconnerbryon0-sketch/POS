allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    beforeEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val cls = androidExt.javaClass
                // Force compileSdk to 36
                try {
                    val setCompileSdk = cls.methods.firstOrNull { it.name == "setCompileSdk" && it.parameterTypes.isNotEmpty() && it.parameterTypes[0] == Int::class.javaPrimitiveType }
                    if (setCompileSdk != null) {
                        setCompileSdk.invoke(androidExt, 36)
                        println("[compile-sdk-patch-before] Set compileSdk(36) for ${project.name}")
                    }
                } catch (_: Exception) {}
                try {
                    val setCompileSdkVersion = cls.methods.firstOrNull { it.name == "setCompileSdkVersion" && it.parameterTypes.isNotEmpty() }
                    if (setCompileSdkVersion != null) {
                        setCompileSdkVersion.invoke(androidExt, 36)
                        println("[compile-sdk-patch-before] Set compileSdkVersion(36) for ${project.name}")
                    }
                } catch (_: Exception) {}
            } catch (_: Exception) {}
        }
    }
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val cls = androidExt.javaClass
                // Try to set namespace if missing
                try {
                    val getNs = cls.getMethod("getNamespace")
                    val ns = getNs.invoke(androidExt)
                    if (ns == null) {
                        val manifest = file("src/main/AndroidManifest.xml")
                        if (manifest.exists()) {
                            val txt = manifest.readText()
                            val m = Regex("package=\"([^\"]+)\"").find(txt)
                            if (m != null) {
                                cls.getMethod("setNamespace", String::class.java).invoke(androidExt, m.groupValues[1])
                                println("[namespace-patch] Set namespace for ${project.name}")
                            } else {
                                cls.getMethod("setNamespace", String::class.java).invoke(androidExt, "com.example.${project.name.replace("-", "_")}")
                                println("[namespace-patch] Set fallback namespace for ${project.name}")
                            }
                        }
                    }
                } catch (_: Exception) {}
                // Force compileSdk to 36 again
                try {
                    val setCompileSdk = cls.methods.firstOrNull { it.name == "setCompileSdk" && it.parameterTypes.isNotEmpty() && it.parameterTypes[0] == Int::class.javaPrimitiveType }
                    if (setCompileSdk != null) {
                        setCompileSdk.invoke(androidExt, 36)
                        println("[compile-sdk-patch] Set compileSdk(36) for ${project.name}")
                    }
                } catch (_: Exception) {}
                try {
                    val setCompileSdkVersion = cls.methods.firstOrNull { it.name == "setCompileSdkVersion" && it.parameterTypes.isNotEmpty() }
                    if (setCompileSdkVersion != null) {
                        setCompileSdkVersion.invoke(androidExt, 36)
                    }
                } catch (_: Exception) {}
            } catch (_: Exception) {}
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
