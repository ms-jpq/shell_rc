#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from json import dumps, loads
from os import fsencode
from os import name as _os
from os import pathconf
from pathlib import Path, PureWindowsPath
from sys import stdin

match _os:
    case "nt":
        _ESCAPES = {
            code: f"%{code:02X}" for code in (*range(32), *map(ord, '%<>:"/\\|?*'))
        }

        def _name(key: str) -> str:
            name = key.translate(_ESCAPES)
            end = len(name.rstrip(" ."))
            trailing = name[end:].replace(" ", "%20").replace(".", "%2E")
            name = name[:end] + trailing
            if PureWindowsPath(name).is_reserved():
                name = f"%{ord(name[0]):02X}" + name[1:]
            if name.lower().endswith(".json"):
                return name[:-5] + "%2E" + name[-4:]
            return name or "%"

    case _:

        def _name(key: str) -> str:
            name = key.replace("%", "%25").replace("/", "%2F").replace("\0", "%00")
            match name:
                case "":
                    return "%"
                case "." | "..":
                    return name.replace(".", "%2E")
                case _:
                    if name.lower().endswith(".json"):
                        return name[:-5] + "%2E" + name[-4:]
                    return name


def _children(value: object) -> tuple[tuple[str, object], ...] | None:
    match value:
        case dict():
            return tuple((_name(key), child) for key, child in value.items())
        case list():
            width = len(str(max(0, len(value) - 1)))
            return tuple(
                (f"{index:0{width}d}", child) for index, child in enumerate(value)
            )
        case _:
            return None


def _fits(destination: Path, *, name_max: int, path_max: int) -> bool:
    return (name_max == -1 or len(fsencode(destination.name)) <= name_max) and (
        path_max == -1 or len(fsencode(destination)) < path_max
    )


def _write(
    value: object,
    *,
    destination: Path,
    leaf: Path,
    depth: int | None,
    name_max: int,
    path_max: int,
    root: bool = False,
) -> None:
    children = _children(value)
    expand = (
        children is not None
        and depth != 0
        and all(
            _fits(destination / (name + ".json"), name_max=name_max, path_max=path_max)
            for name, _ in children
        )
    )
    if expand:
        if not root:
            destination.mkdir()
        for name, child in children:
            _write(
                child,
                destination=destination / name,
                leaf=destination / (name + ".json"),
                depth=None if depth is None else depth - 1,
                name_max=name_max,
                path_max=path_max,
            )
    else:
        with leaf.open(mode="x", encoding="utf-8") as stream:
            stream.write(
                dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
            )


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    parser.add_argument("destination", type=Path)
    parser.add_argument("-d", "--depth", type=int)
    args = parser.parse_args()
    if args.depth is not None and args.depth < 0:
        parser.error("depth must be nonnegative")
    return args


def _main() -> None:
    args = _parse_args()
    value = loads(stdin.read())
    destination = args.destination.absolute()
    name_max = pathconf(destination.parent, "PC_NAME_MAX")
    path_max = pathconf(destination.parent, "PC_PATH_MAX")
    leaf = destination / "value.json"
    destination.mkdir()
    _write(
        value,
        destination=destination,
        leaf=leaf,
        depth=args.depth,
        name_max=name_max,
        path_max=path_max,
        root=True,
    )


_main()
