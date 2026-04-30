#!/usr/bin/env -S -- kotlinc -script
@file:OptIn(kotlin.io.path.ExperimentalPathApi::class)

import java.lang.ProcessBuilder.Redirect
import kotlin.io.path.Path
import kotlin.io.path.copyToRecursively
import kotlin.io.path.createDirectories
import kotlin.io.path.createSymbolicLinkPointingTo
import kotlin.io.path.deleteIfExists

val run = Path(System.getenv("RUN")!!)
val lib = Path(System.getenv("LIB")!!)
val launcher = lib.resolve("bin").resolve("intellij-server")
val bin = Path(System.getenv("BIN")!!).resolve("kotlin-lsp")
val repo = "Kotlin/kotlin-lsp"

val p1 =
    ProcessBuilder("env", "--", "gh-latest.sh", ".", repo).redirectError(Redirect.INHERIT).start()

val code = p1.waitFor()

if (code != 0) {
  System.exit(code)
}

val version = String(p1.getInputStream().readAllBytes()).replaceFirst("kotlin-lsp/v", "")

val ext =
    when {
      System.getProperty("os.name").startsWith("Windows") -> "win.zip"
      System.getProperty("os.name").startsWith("Mac") -> "sit"
      else -> "tar.gz"
    }

val arch =
    when (System.getProperty("os.arch")) {
      "aarch64",
      "army64" -> "-aarch64"
      else -> ""
    }

val dir = "kotlin-server-$version"

val uri = "https://download-cdn.jetbrains.com/kotlin-lsp/$version/$dir$arch.$ext"

run.toFile().mkdirs()

val procs =
    ProcessBuilder.startPipeline(
        listOf(
            ProcessBuilder("env", "--", "get.sh", uri).redirectError(Redirect.INHERIT),
            ProcessBuilder("env", "--", "unpack.sh", run.toString())
                .redirectOutput(Redirect.INHERIT)
                .redirectError(Redirect.INHERIT),
        )
    )

procs.forEach {
  val code = it.waitFor()
  if (code != 0) {
    System.exit(code)
  }
}

lib.toFile().deleteRecursively()

lib.createDirectories()

run.resolve(dir).copyToRecursively(lib, followLinks = false)

bin.getParent().createDirectories()

bin.deleteIfExists()

bin.createSymbolicLinkPointingTo(launcher)
