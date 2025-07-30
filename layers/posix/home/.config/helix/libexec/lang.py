#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from json import loads as load_json
from pathlib import Path

from tomli import loads
from tomli_w import dumps


def _main() -> None:
    codec = "utf-8"
    libexec = Path(__file__).resolve(strict=True).parent.parent
    online = libexec.parent.parent.parent.parent.parent / "var" / "helix.lang.toml"

    src = libexec / "languages.json"
    dst = libexec / "languages.toml"

    preset = loads(online.read_text(codec))
    languages = {
        l.pop("name"): l.get("language-servers", []) for l in preset["language"]
    }

    json = load_json(src.read_text(codec))
    common = json["$"]

    acc = []
    for name, language in json["language"].items():
        lsps = language.get("language-servers", [])
        lsps.extend(languages.pop(name, ()))
        lsps.extend(common)
        acc.append({"name": name, **language})

    for name, lsps in languages.items():
        lsps.extend(common)
        acc.append({"name": name, "language-servers": lsps})

    toml = dumps({"language": acc, "language-server": json["language-server"]})
    dst.write_text(toml)


_main()
