#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from json import loads
from pathlib import Path

from tomli_w import dumps

root = Path(__file__).resolve(strict=True).parent.parent

src = root / "languages.json"
dst = root / "languages.toml"

json = loads(src.read_text())
common, ls = json["$"], json["language"]
acc = []

for name, language in json["language"].items():
    if lsps := language.get("language-servers"):
        lsps.extend(common)
    acc.append({"name": name, **language})

toml = dumps({"language": acc, "language-server": json["language-server"]})
dst.write_text(toml)
