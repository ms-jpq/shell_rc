#!/usr/bin/env -S -- java -enableassertions --source 25

import java.nio.file.Path;
import java.util.stream.Stream;

void main(String[] args) throws Exception {
  final var java = ProcessHandle.current().info().command().orElseThrow();
  final var jar =
      Path.of(System.getProperty("user.home"))
          .resolve(".cache")
          .resolve("helix-rt")
          .resolve("more")
          .resolve("lemminx.java")
          .resolve("lib")
          .resolve("org.eclipse.lemminx-uber.jar");
  final var workdir = Path.of(System.getProperty("java.io.tmpdir")).resolve("lemminx");
  final var argv =
      Stream.concat(
              Stream.of(java, "-Dlemminx.workdir=" + workdir, "-jar", jar.toString()),
              Stream.of(args))
          .toArray(String[]::new);

  final var proc = new ProcessBuilder(argv).inheritIO().start();
  assert proc.waitFor() == 0;
}
