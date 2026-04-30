// ; exec java -enableassertions -Dprogram.name="$0" "$0" "$@"

import java.lang.ProcessBuilder.Redirect;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Objects;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPathFactory;

void main() throws Exception {
  final var lib = Path.of(Objects.requireNonNull(System.getenv("LIB")));
  final var dst = lib.resolve("org.eclipse.lemminx-uber.jar");
  final var base =
      URI.create(
          "https://repo.eclipse.org/content/repositories/lemminx-releases/org/eclipse/lemminx/org.eclipse.lemminx/");

  final var builder =
      DocumentBuilderFactory.newInstance()
          .newDocumentBuilder()
          .parse(base.resolve("maven-metadata.xml").toString());
  final var version =
      XPathFactory.newInstance()
          .newXPath()
          .evaluate("/metadata/versioning/versions/version[last()]", builder);

  final var uri =
      base.resolve(version + "/")
          .resolve("org.eclipse.lemminx-" + version + "-uber.jar")
          .toString();

  final var p =
      new ProcessBuilder("env", "--", "get.sh", uri).redirectError(Redirect.INHERIT).start();
  assert p.waitFor() == 0;
  final var jar = new String(p.getInputStream().readAllBytes());

  Files.createDirectories(lib);
  Files.copy(Path.of(jar), dst, StandardCopyOption.REPLACE_EXISTING);
}
