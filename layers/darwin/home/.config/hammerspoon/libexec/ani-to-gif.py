#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from collections.abc import Iterator
from pathlib import Path
from struct import unpack_from
from subprocess import check_call
from tempfile import TemporaryDirectory


def _chunks(data: bytes, *, start: int, stop: int) -> Iterator[tuple[bytes, bytes]]:
    offset = start
    while offset < stop:
        kind = data[offset : offset + 4]
        size = unpack_from("<I", data, offset + 4)[0]
        payload = offset + 8
        yield kind, data[payload : payload + size]
        offset = payload + size + size % 2


def _frames(data: bytes) -> Iterator[bytes]:
    assert data[:4] == b"RIFF" and data[8:12] == b"ACON"

    for kind, payload in _chunks(data, start=12, stop=len(data)):
        match kind, payload[:4]:
            case b"LIST", b"fram":
                yield from (
                    frame
                    for kind, frame in _chunks(payload, start=4, stop=len(payload))
                    if kind == b"icon"
                )


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    parser.add_argument("src")
    parser.add_argument("dst")
    parser.add_argument("--fps", type=float, default=10)
    return parser.parse_args()


def _main() -> None:
    args = _parse_args()
    src, dst = Path(args.src), Path(args.dst)

    frames = tuple(_frames(src.read_bytes()))
    assert frames

    dst.parent.mkdir(parents=True, exist_ok=True)

    with TemporaryDirectory() as d:
        tmp = Path(d)

        for index, frame in enumerate(frames):
            cursor = tmp / f"{index:04}.cur"
            png = cursor.with_suffix(".png")
            cursor.write_bytes(frame)
            check_call(
                ("sips", "--setProperty", "format", "png", cursor, "--out", png),
            )
        check_call(
            (
                "ffmpeg",
                "-hide_banner",
                "-loglevel",
                "error",
                "-y",
                "-framerate",
                str(args.fps),
                "-start_number",
                "0",
                "-i",
                str(tmp / "%04d.png"),
                "-filter_complex",
                "[0:v]split[frames][palette];[palette]palettegen=reserve_transparent=1[colors];[frames][colors]paletteuse=alpha_threshold=1",
                "-loop",
                "0",
                dst,
            ),
        )


_main()
