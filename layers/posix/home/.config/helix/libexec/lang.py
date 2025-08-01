#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from collections.abc import MutableMapping
from json import loads as load_json
from pathlib import Path
from typing import Any

from tomli import loads
from tomli_w import dumps


def _merge_indent(
    row: MutableMapping[str, Any], indent: MutableMapping[str, Any]
) -> None:
    if (unit := indent.get("unit", "")) == "\t":
        row["indent"] = {"unit": unit, "tab-width": 2}
    elif unit == " " * 4:
        row["indent"] = {"unit": " " * 2, "tab-width": 2}


def _main() -> None:
    codec = "utf-8"
    libexec = Path(__file__).resolve(strict=True).parent.parent
    online = libexec.parent.parent.parent.parent.parent / "var" / "helix.lang.toml"

    src = libexec / "languages.json"
    dst = libexec / "languages.toml"

    preset = loads(online.read_text(codec))
    languages = {
        l.pop("name"): (l.get("language-servers", []), l.get("indent", {}))
        for l in preset["language"]
    }

    json = load_json(src.read_text(codec))
    common = json["$"]

    acc = []
    for name, language in json["language"].items():
        ls, indent = languages.pop(name, ((), {}))
        lsps = language.get("language-servers", [])
        lsps.extend(ls)
        lsps.extend(common)
        row = {"name": name, **language}
        _merge_indent(row, indent=indent)
        acc.append(row)

    for name, (lsps, indent) in languages.items():
        lsps.extend(common)
        row = {"name": name, "language-servers": lsps}
        _merge_indent(row, indent=indent)
        acc.append(row)

    toml = dumps({"language": acc, "language-server": json["language-server"]})
    dst.write_text(toml)


_main()
