#!/usr/bin/env -S -- java -enableassertions --source 25

import java.nio.file.Path;
import java.util.stream.Stream;

void main(String[] args) throws Exception {
  final var tabsize = Integer.parseInt(args[0]);
  final var java = Path.of(System.getProperty("java.home")).resolve("bin").resolve("java");
  final var jar =
      Path.of(System.getProperty("user.home"))
          .resolve(".cache")
          .resolve("helix-rt")
          .resolve("more")
          .resolve("ktfmt.kts")
          .resolve("lib")
          .resolve("ktfmt.jar");

  final var argv =
      Stream.of(
              Stream.of(java.toString(), "-jar", jar.toString()),
              Stream.of(args).skip(1),
              tabsize == 4 ? Stream.of("--kotlinlang-style") : Stream.of())
          .flatMap(s -> s)
          .toArray(String[]::new);

  final var proc = new ProcessBuilder(argv).inheritIO().start();
  assert proc.waitFor() == 0;
}
