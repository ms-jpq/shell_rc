// ; exec java -ea -Dprogram.name="$0" "$0" "$@"

import java.nio.file.Path;
import java.util.stream.Stream;

public class javafmt {
  public static void main(String args[]) throws Exception {
    final var java = Path.of(System.getProperty("java.home")).resolve("bin").resolve("java");
    final var jar =
        Path.of(System.getProperty("user.home"))
            .resolve(".cache")
            .resolve("helix-rt")
            .resolve("more")
            .resolve("javafmt.java")
            .resolve("lib")
            .resolve("google-java-format.jar");
    final var argv =
        Stream.concat(Stream.of(java.toString(), "-jar", jar.toString()), Stream.of(args))
            .toArray(String[]::new);

    final var proc = new ProcessBuilder(argv).inheritIO().start();
    assert proc.waitFor() == 0;
  }
}
