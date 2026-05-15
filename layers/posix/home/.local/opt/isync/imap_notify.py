#!/usr/bin/env -S -- PYTHONSAFEPATH= /opt/homebrew/bin/python3

from argparse import ArgumentParser, Namespace
from collections.abc import Generator, Iterator
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager, nullcontext, suppress
from functools import cache, lru_cache, partial
from imaplib import IMAP4, IMAP4_SSL
from itertools import islice
from logging import INFO, basicConfig, captureWarnings, getLogger
from os import linesep
from pathlib import Path
from socket import gaierror
from string import Template
from subprocess import STDOUT, CalledProcessError, check_output
from sys import argv, exit
from threading import Lock
from time import monotonic, sleep

_MINUTE, _IDLE = 60, 25 * 60
_FILE = Path(__file__).resolve()


with nullcontext():
    captureWarnings(True)
    basicConfig(format="%(message)s", level=INFO)


@cache
def _lock() -> Lock:
    return Lock()


@lru_cache(maxsize=1)
def _auth(authn: str, user: str, now: int) -> bytes:
    parent = _FILE.parent
    state = Path.home() / ".local" / "state" / parent.name

    match authn:
        case "oauth":
            argv = (parent / "oauth.sh", "--", state / f"{user}.oauth.gpg")
            try:
                out = check_output(argv, text=True, timeout=_MINUTE, stderr=STDOUT)
            except CalledProcessError as e:
                getLogger().error("%s\n%s", e, e.output)
                raise
            return f"user={user}\1auth=Bearer {out.rstrip()}\1\1".encode()
        case "plain":
            return state.joinpath(f"{user}.password").read_bytes().strip()
        case _:
            assert False


@contextmanager
def _imap(host: str, authn: str, user: str) -> Generator[IMAP4]:
    now = int(monotonic() / _MINUTE)
    with _lock():
        auth = _auth(authn, user=user, now=now)

    m = IMAP4_SSL(host=host, timeout=_MINUTE * 1.1)
    try:
        match authn:
            case "oauth":
                ok, _ = m.authenticate("XOAUTH2", lambda _: auth)
                assert ok == "OK", ok
            case "plain":
                m.login(user, password=auth.decode())

        m._get_capabilities()
        yield m
    finally:
        with suppress(IMAP4.error, OSError):
            m.logout()


def _mailboxes(m: IMAP4) -> Iterator[str]:
    ok, data = m.list()
    assert ok == "OK", ok
    sep = b' "/" '
    for row in data:
        assert isinstance(row, bytes), row
        _, s, dir = row.partition(sep)
        assert s == sep, s
        yield dir.decode()


def _waiting(host: str, authn: str, user: str, mailbox: str) -> Iterator[None]:
    with _imap(host, authn=authn, user=user) as m:
        ok, _ = m.select(mailbox, readonly=True)
        assert ok == "OK", ok

        with m.idle(duration=_IDLE) as idler:
            for typ, data in idler:
                getLogger().info("%s", f"{mailbox} -> {typ} {data!r}")
                if typ == "BYE":
                    return
                yield None


def _trigger(channel: str) -> None:
    trigger = (
        Path.home()
        / ".local"
        / "state"
        / "isync"
        / f"mbsync.{channel}.watch"
        / "trigger"
    )
    trigger.touch()
    getLogger().info("%s", f">> {trigger}")


def _idle(
    daemon: float, channel: str, host: str, authn: str, user: str, mailbox: str
) -> None:
    daemonize, touched = daemon > 0, False
    while daemonize or not touched:
        touched = True
        try:
            for _ in _waiting(host, authn=authn, user=user, mailbox=mailbox):
                _trigger(channel)
        except (TimeoutError, gaierror, CalledProcessError) as e:
            getLogger().info("%s", e)
        except IMAP4.abort as e:
            getLogger().warning("%s", e)
        except IMAP4.error as e:
            getLogger().exception("%s", e)
        finally:
            if daemonize:
                getLogger().info("%s", f"    :: {mailbox}")
                sleep(daemon)


def _install(channel: str, path: Path) -> None:
    raw = _FILE.parent.joinpath("imap.notify.channel.xml").read_text()
    template = Template(raw)
    av = linesep.join(
        (
            "-->",
            *(
                f"<string>{a}</string>"
                for a in islice(argv, 1, None)
                if a != "--install"
            ),
            "<!--",
        )
    )
    rendered = template.substitute(
        HOME=Path.home(),
        CHANNEL=channel,
        SELF=_FILE.with_suffix(".sh").name,
        ARGV=av,
    )
    path.write_text(rendered)
    getLogger().info("%s", rendered)


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    with nullcontext(parser.add_mutually_exclusive_group()) as mutex:
        mutex.add_argument("--install", action="store_true")
        mutex.add_argument("--remove", action="store_true")

    parser.add_argument("--host", default="outlook.office365.com")
    parser.add_argument("--boxes", nargs="*", default=("INBOX",))
    parser.add_argument("--auth", choices=("oauth", "plain"), default="oauth")
    parser.add_argument("--daemon", type=float, default=0)
    parser.add_argument("--channel", required=True)
    parser.add_argument("--user", required=True)
    return parser.parse_args()


def main() -> None:
    try:
        args = _parse_args()
        channel, host, authn, user = args.channel, args.host, args.auth, args.user

        launchd = (
            Path.home() / "Library" / "LaunchAgents" / f"imap.notify.{channel}.plist"
        )

        match args.remove, args.install:
            case True, _:
                return launchd.unlink(missing_ok=True)
            case _, True:
                return _install(channel, path=launchd)

        idle = partial(_idle, args.daemon, channel, host, authn, user)

        if not (mailbox_names := args.boxes):
            with _imap(host, authn=authn, user=user) as m:
                mailbox_names = tuple(_mailboxes(m))

        getLogger().info("%s", launchd)
        with ThreadPoolExecutor() as ex:
            tuple(ex.map(idle, mailbox_names))
    except Exception as e:
        getLogger().exception("%s", e)
        raise


try:
    main()
except KeyboardInterrupt:
    exit(130)
