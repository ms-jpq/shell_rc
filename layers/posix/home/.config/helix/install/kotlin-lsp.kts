#!/usr/bin/env -S -- kotlinc -script
import java.lang.ProcessBuilder.Redirect
import kotlin.io.path.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.createSymbolicLinkPointingTo
import kotlin.io.path.deleteIfExists

val lib = Path(System.getenv("LIB")!!)
val sh = lib.resolve("kotlin-lsp.sh")
val bin = Path(System.getenv("BIN")!!).resolve("kotlin-lsp")
val repo = "Kotlin/kotlin-lsp"

val p1 =
    ProcessBuilder("env", "--", "gh-latest.sh", ".", repo).redirectError(Redirect.INHERIT).start()

val code = p1.waitFor()

if (code != 0) {
  System.exit(code)
}

val uri =
    {
      val version = String(p1.getInputStream().readAllBytes()).replaceFirst("kotlin-lsp/v", "")
      val name = System.getProperty("os.name")
      val os =
          when {
            name.startsWith("Windows") -> "win"
            name.startsWith("Mac") -> "mac"
            else -> "linux"
          }

      val arch =
          when (System.getProperty("os.arch")) {
            "aarch64",
            "army64" -> "aarch64"
            else -> "x64"
          }

      "https://download-cdn.jetbrains.com/kotlin-lsp/$version/kotlin-lsp-$version-$os-$arch.zip"
    }()

lib.toFile().mkdirs()

val procs =
    ProcessBuilder.startPipeline(
        listOf(
            ProcessBuilder("env", "--", "get.sh", uri).redirectError(Redirect.INHERIT),
            ProcessBuilder("env", "--", "unpack.sh", lib.toString())
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

bin.getParent().createDirectories()

bin.deleteIfExists()

bin.createSymbolicLinkPointingTo(sh)
