from argparse import ArgumentParser, Namespace
from contextlib import closing, suppress
from dataclasses import asdict, dataclass
from functools import cache, partial
from ipaddress import IPv4Address, IPv6Address, ip_address
from itertools import count
from json import dumps, loads
from json.decoder import JSONDecodeError
from locale import str as format_float
from math import inf, isfinite
from operator import pow
from os import environ
from pathlib import Path
from platform import system
from socket import AddressFamily, socket, timeout
from sys import stdout
from tempfile import NamedTemporaryFile, gettempdir
from time import monotonic, sleep, time
from typing import Iterator, Mapping, Optional, Tuple, Union
from urllib.parse import quote

_SCALE = "▁▂▃▄▅▆▇█"


@dataclass(frozen=True)
class _Colours:
    lo: str
    md: str
    hi: str
    tr: str


@dataclass(frozen=True)
class _Snapshot:
    time: float
    cpu_times: Mapping[str, float]
    disk_read: int
    disk_write: int
    net_sent: int
    net_recv: int


@dataclass(frozen=True)
class _Stats:
    cpu: float
    mem: Optional[float]
    disk_read: float
    disk_write: float
    net_sent: float
    net_recv: float


@cache
def _path() -> Path:
    mux, _, _ = environ["TMUX"].partition(",")
    p = (
        Path(environ.get("TMUX_TMPDIR", gettempdir()))
        / "tmux-status-line"
        / quote(mux, safe="")
    )
    return p.with_suffix(".json")


def _dump(path: Path, thing: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=path.parent, mode="w", delete=False) as fd:
        fd.write(thing)
    Path(fd.name).replace(path)


def _human_readable_size(size: float, precision: int = 3) -> str:
    units = ("", "K", "M", "G", "T", "P", "E", "Z", "Y")
    step = partial(pow, 10)
    steps = zip(map(step, count(0, step=3)), units)
    for factor, unit in steps:
        divided = size / factor
        if abs(divided) < 1000:
            fmt = format_float(round(divided, precision))
            return f"{fmt}{unit}"
    else:
        raise ValueError(f"unit over flow: {size}")


def _ip() -> Union[IPv6Address, IPv4Address, None]:
    try:
        ip = _path().with_suffix(".ip").read_text()
    except FileNotFoundError:
        if client := environ.get("SSH_CLIENT"):
            ip, *_ = client.split()
            return ip_address(ip)
        else:
            return None
    else:
        return ip_address(ip)


def _ssh(deadline: float) -> Optional[float]:
    if ip := _ip():
        fam = (
            AddressFamily.AF_INET6
            if isinstance(ip, IPv6Address)
            else AddressFamily.AF_INET
        )
        now = monotonic()
        with closing(socket(fam)) as sock:
            sock.settimeout(deadline)
            with suppress(OSError):
                try:
                    sock.connect((str(ip), 22))
                except timeout:
                    return inf
        return (monotonic() - now) * 2
    else:
        return None


def _load() -> Optional[_Snapshot]:
    try:
        raw = _path().read_text()
        json = loads(raw)
        snapshot = _Snapshot(**json)
    except (FileNotFoundError, JSONDecodeError):
        _path().unlink(missing_ok=True)
        return None
    else:
        return snapshot


def _snap() -> Optional[_Snapshot]:
    try:
        from psutil import cpu_times, disk_io_counters, net_io_counters
    except ImportError:
        return None
    else:
        t = time()
        cpu = cpu_times()
        disk = disk_io_counters()
        net = net_io_counters()
        snapshot = _Snapshot(
            time=t,
            cpu_times=cpu._asdict(),
            disk_read=disk.read_bytes if disk else 0,
            disk_write=disk.write_bytes if disk else 0,
            net_sent=net.bytes_sent,
            net_recv=net.bytes_recv,
        )
        return snapshot


def _states(interval: int) -> Optional[Tuple[_Snapshot, _Snapshot, Optional[int]]]:
    if s1 := _load() or _snap():
        try:
            from psutil import sensors_battery
        except ImportError:
            battery = None
        else:
            battery = sensors_battery()  # type: ignore

        sleep(max(0, interval - (time() - s1.time)))
        if s2 := _snap():
            json = dumps(asdict(s2), check_circular=False, ensure_ascii=False)
            _dump(_path(), thing=json)
            return s1, s2, battery.percent if battery else None

    return None


def _cpu(delta: Mapping[str, float]) -> float:
    tot = sum(delta.values())
    if system() == "Linux":
        tot -= delta.get("guest", 0)
        tot -= delta.get("guest_nice", 0)

    busy = tot
    busy -= delta["idle"]
    busy -= delta.get("iowait", 0)

    try:
        return busy / tot
    except ZeroDivisionError:
        return 0


def _measure(s1: _Snapshot, s2: _Snapshot) -> _Stats:
    time_adjust = 1 / (s2.time - s1.time)
    cpu_delta = {
        k: max(0, v2 - v1)
        for (k, v1), (_, v2) in zip(s1.cpu_times.items(), s2.cpu_times.items())
    }
    try:
        from psutil import virtual_memory

        vm = virtual_memory()
    except ImportError:
        mem = None
    else:
        mem = 1 - vm.available / vm.total

    stats = _Stats(
        cpu=_cpu(cpu_delta) * time_adjust,
        mem=mem,
        disk_read=max(0, s2.disk_read - s1.disk_read) * time_adjust,
        disk_write=max(0, s2.disk_write - s1.disk_write) * time_adjust,
        net_sent=max(0, s2.net_sent - s1.net_sent) * time_adjust,
        net_recv=max(0, s2.net_recv - s1.net_recv) * time_adjust,
    )
    return stats


def _colour(lo: float, hi: float, val: float, text: str, colours: _Colours) -> str:
    if val < lo:
        return f"#[bg={colours.lo}]{text}{colours.tr}"
    elif val < hi:
        return f"#[bg={colours.md}]{text}{colours.tr}"
    else:
        return f"#[bg={colours.hi}]{text}{colours.tr}"


# def _style(style: str, text: str) -> str:
#     return f"#[{style}]{text}#[none]"


def _stat_lines(
    lo: float, hi: float, interval: int, colours: _Colours
) -> Iterator[str]:
    if (ssh := _ssh(interval)) is not None:
        ping = (
            "~ " + format(ssh * 1000, ".1f")
            if isfinite(ssh)
            else "> " + format(interval * 1000, ".0f")
        )
        yield f"SSH {ping}ms"

    if states := _states(interval):
        s1, s2, battery = states
        stats = _measure(s1, s2)

        cpu = format(stats.cpu, "4.0%")

        hr_dr = _human_readable_size(stats.disk_read, precision=0)
        hr_dw = _human_readable_size(stats.disk_write, precision=0)
        hr_ns = _human_readable_size(stats.net_sent, precision=0)
        hr_nr = _human_readable_size(stats.net_recv, precision=0)

        disk_read, disk_write = f"{hr_dr}B".rjust(5), f"{hr_dw}B".rjust(5)
        net_sent, net_recv = f"{hr_ns}B".rjust(5), f"{hr_nr}B".rjust(5)

        yield f"[⇡ {net_sent}, ⇣ {net_recv}]"
        yield f"[r {disk_read}, w {disk_write}]"
        yield _colour(lo, hi, val=stats.cpu, text=f" λ{cpu} ", colours=colours)
        if stats.mem is not None:
            mem = format(stats.mem, "4.0%")
            yield _colour(lo, hi, val=stats.mem, text=f" τ{mem} ", colours=colours)

        if battery is not None:
            b = _SCALE[int(battery / 100 * (len(_SCALE) - 1))]
            yield f"┇{b}┇"


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    parser.add_argument("--lo", type=float, required=True)
    parser.add_argument("--hi", type=float, required=True)
    parser.add_argument("--interval", type=float, required=True)
    parser.add_argument("--colour-lo", default="")
    parser.add_argument("--colour-md", default="")
    parser.add_argument("--colour-hi", default="")
    parser.add_argument("--colour-tr", default="")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    colours = _Colours(
        lo=args.colour_lo, md=args.colour_md, hi=args.colour_hi, tr=args.colour_tr
    )
    lines = _stat_lines(args.lo, args.hi, interval=args.interval, colours=colours)
    stream = " ".join(lines)
    stdout.write(stream)


main()
