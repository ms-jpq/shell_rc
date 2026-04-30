// ; exec java -enableassertions -Dprogram.name="$0" "$0" "$@"

import java.lang.ProcessBuilder.Redirect;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Objects;

public class javafmt {
  public static void main(String args[]) throws Exception {
    final var lib = Path.of(Objects.requireNonNull(System.getenv("LIB")));
    final var dst = lib.resolve("google-java-format.jar");
    final var repo = "google/google-java-format";

    final var p1 =
        new ProcessBuilder("env", "--", "gh-latest.sh", ".", repo)
            .redirectError(Redirect.INHERIT)
            .start();
    assert p1.waitFor() == 0;
    final var version = new String(p1.getInputStream().readAllBytes());

    final var uri =
        "https://github.com/"
            + repo
            + "/releases/latest/download/google-java-format-"
            + version.replaceFirst("^v", "")
            + "-all-deps.jar";
    final var p2 =
        new ProcessBuilder("env", "--", "get.sh", uri).redirectError(Redirect.INHERIT).start();
    assert p2.waitFor() == 0;
    final var jar = new String(p2.getInputStream().readAllBytes());

    Files.createDirectories(lib);
    Files.copy(Path.of(jar), dst, StandardCopyOption.REPLACE_EXISTING);
  }
}
