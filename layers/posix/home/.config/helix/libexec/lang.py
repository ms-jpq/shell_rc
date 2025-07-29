#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from json import loads as load_json
from pathlib import Path

from tomli import loads
from tomli_w import dumps

libexec = Path(__file__).resolve(strict=True).parent.parent
online = libexec.parent.parent.parent.parent.parent / "var" / "helix.lang.toml"

src = libexec / "languages.json"
dst = libexec / "languages.toml"

preset = loads(online.read_text())
languages = {l["name"]: l.get("language-servers", ()) for l in preset["language"]}

json = load_json(src.read_text())
common, ls = json["$"], json["language"]

acc = []
for name, language in json["language"].items():
    lsps = language.get("language-servers", [])
    lsps.extend(languages.get(name, ()))
    lsps.extend(common)
    acc.append({"name": name, **language})

toml = dumps({"language": acc, "language-server": json["language-server"]})
dst.write_text(toml)
