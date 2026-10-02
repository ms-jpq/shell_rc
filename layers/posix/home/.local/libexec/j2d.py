#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from collections.abc import Iterator
from contextlib import suppress
from itertools import count
from json import dumps, loads
from os import altsep, fsencode
from os import name as _os
from os import sep
from pathlib import Path, PureWindowsPath
from sys import stdin

match _os:
    case "nt":
        _ESCAPES = {
            code: f"%{code:02X}"
            for code in (*range(32), *map(ord, f'%<>:"|?*{sep}{altsep}'))
        }

        def _limits(dst: Path) -> tuple[int, int]:
            return 255, 248

        def _length(value: str) -> int:
            return len(value.encode("utf-16-le", errors="surrogatepass")) // 2

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
        from os import pathconf

        _ESCAPES = {ord(char): f"%{ord(char):02X}" for char in f"%\0{sep}"}

        def _limits(dst: Path) -> tuple[int, int]:
            return (
                pathconf(dst.parent, "PC_NAME_MAX"),
                pathconf(dst.parent, "PC_PATH_MAX"),
            )

        def _length(value: str) -> int:
            return len(fsencode(value))

        def _name(key: str) -> str:
            match (name := key.translate(_ESCAPES)):
                case "":
                    return "%"
                case "." | "..":
                    return name.replace(".", "%2E")
                case _:
                    if name.lower().endswith(".json"):
                        return name[:-5] + "%2E" + name[-4:]
                    return name


def _children(value: object) -> Iterator[tuple[str, object]]:
    match value:
        case dict():
            for key, child in value.items():
                yield _name(key), child
        case list():
            width = len(str(max(0, len(value) - 1)))
            for index, child in enumerate(value):
                yield f"{index:0{width}d}", child
        case _:
            return


def _fits(dst: Path, *, name_max: int, path_max: int) -> bool:
    return (name_max == -1 or _length(dst.name) <= name_max) and (
        path_max == -1 or _length(str(dst)) < path_max
    )


def _candidates(dst: Path) -> Iterator[Path]:
    for index in count():
        match index:
            case 0:
                yield dst
            case 1:
                yield dst.with_name(f"{dst.name}.~")
            case _:
                yield dst.with_name(f"{dst.name}.~{index}")


def _expand(
    value: object,
    *,
    dst: Path,
    depth: int | None,
    name_max: int,
    path_max: int,
) -> bool:
    suffix = f".~{len(value)}" if isinstance(value, dict) and len(value) > 1 else ""
    return (
        isinstance(value, (dict, list))
        and depth != 0
        and all(
            _fits(dst / (name + suffix + ".json"), name_max=name_max, path_max=path_max)
            for name, _ in _children(value)
        )
    )


def _walk(
    value: object,
    *,
    dst: Path,
    depth: int | None,
    name_max: int,
    path_max: int,
) -> Iterator[tuple[Path, object]]:
    depth = None if depth is None else depth - 1
    for name, child in _children(value):
        for candidate in _candidates(dst / name):
            directory = _expand(
                child,
                dst=candidate,
                depth=depth,
                name_max=name_max,
                path_max=path_max,
            )
            if not directory:
                break
            with suppress(FileExistsError):
                candidate.mkdir()
                break
        else:
            assert False
        if directory:
            yield from _walk(
                child,
                dst=candidate,
                depth=depth,
                name_max=name_max,
                path_max=path_max,
            )
        else:
            yield candidate, child


def _write(value: object, *, dst: Path) -> None:
    for candidate in _candidates(dst):
        leaf = candidate.with_name(candidate.name + ".json")
        with suppress(FileExistsError):
            stream = leaf.open(mode="x", encoding="utf-8")
            break
    else:
        assert False

    with stream:
        stream.write(dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n")


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    parser.add_argument("dst", type=Path)
    parser.add_argument("-d", "--depth", type=int)
    args = parser.parse_args()
    if args.depth is not None and args.depth < 0:
        parser.error(f"depth={args.depth}")
    return args


def _main() -> None:
    args = _parse_args()
    value = loads(stdin.read())
    dst = args.dst.absolute()
    name_max, path_max = _limits(dst)

    dst.mkdir()
    if _expand(
        value,
        dst=dst,
        depth=args.depth,
        name_max=name_max,
        path_max=path_max,
    ):
        for child_dst, child in _walk(
            value,
            dst=dst,
            depth=args.depth,
            name_max=name_max,
            path_max=path_max,
        ):
            _write(child, dst=child_dst)
    else:
        _write(value, dst=dst / "-")


_main()
