#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from collections.abc import Generator, Iterator
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager, nullcontext, suppress
from functools import cache, lru_cache, partial
from imaplib import IMAP4, IMAP4_SSL, Commands
from itertools import islice
from logging import INFO, LogRecord, basicConfig, captureWarnings, getLogger
from logging.handlers import SysLogHandler
from os import linesep
from pathlib import Path
from platform import system
from selectors import EVENT_READ, DefaultSelector
from socket import gaierror
from string import Template
from subprocess import CalledProcessError, check_output
from sys import argv, exit
from syslog import LOG_MAIL, openlog, syslog
from threading import Lock
from time import monotonic, sleep

_MINUTE, _CYCLE, _PULSE = 60, 9, 2
_FILE = Path(__file__).resolve()


with nullcontext():
    Commands["IDLE"] = ("SELECTED",)


@cache
def _lock() -> Lock:
    return Lock()


@lru_cache(maxsize=1)
def _auth(authn: str, user: str, now: int) -> bytes:
    parent = _FILE.parent
    state = Path.home() / ".local" / "state" / parent.name

    if authn == "oauth":
        argv = (parent / "oauth.sh", "--", state / f"{user}.oauth.gpg")
        password = check_output(argv, text=True, timeout=_MINUTE).rstrip()
        return f"user={user}\1auth=Bearer {password}\1\1".encode()
    elif authn == "plain":
        return state.joinpath(f"{user}.password").read_bytes().strip()
    else:
        assert False


@contextmanager
def _imap(host: str, authn: str, user: str) -> Generator[IMAP4]:
    now = int(monotonic() / _MINUTE)
    with _lock():
        auth = _auth(authn, user=user, now=now)

    cooked = False
    m = IMAP4_SSL(host=host, timeout=_MINUTE * 1.1)
    try:
        if authn == "oauth":
            ok, _ = m.authenticate("XOAUTH2", lambda _: auth)
            assert ok == "OK", ok
        elif authn == "plain":
            m.login(user, password=auth.decode())

        yield m
    except TimeoutError:
        cooked = True
        raise
    finally:
        if not cooked:
            with suppress(IMAP4.abort):
                m.logout()


def _boxes(m: IMAP4) -> Iterator[str]:
    ok, data = m.list()
    assert ok == "OK", ok
    sep = b' "/" '
    for row in data:
        assert isinstance(row, bytes), row
        _, s, dir = row.partition(sep)
        assert s == sep, s
        yield dir.decode()


# https://github.com/python/cpython/issues/55454
def _waiting(host: str, authn: str, user: str, mailbox: str) -> Iterator[None]:
    with DefaultSelector() as sel, _imap(host, authn=authn, user=user) as m:
        sel.register(m.file, EVENT_READ)

        ok, _ = m.select(mailbox, readonly=True)
        assert ok == "OK", ok

        for _ in range(_CYCLE):
            tag = m._command("IDLE")
            cooked = False

            try:
                for _ in range(_PULSE):
                    if sel.select(timeout=_MINUTE):
                        line = m._get_line()
                        assert isinstance(line, bytes)
                        lo = line.lower()

                        getLogger().info("%s", f"{mailbox} -> {line!r}")

                        if lo.startswith(b"* bye"):
                            return

                        if not lo.startswith(b"+ idl"):
                            yield None

                        if line.endswith(b"EXISTS"):
                            break

            except BaseException:
                cooked = True
                raise
            finally:
                if not cooked:
                    m.send(b"DONE\r\n")
                    m._command_complete("IDLE", tag)


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
        HOME=Path.home(), CHANNEL=channel, SELF=_FILE.name, ARGV=av
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

        if args.remove:
            return launchd.unlink(missing_ok=True)
        elif args.install:
            return _install(channel, path=launchd)

        idle = partial(_idle, args.daemon, channel, host, authn, user)

        if not (boxes := args.boxes):
            with _imap(host, authn=authn, user=user) as m:
                boxes = tuple(_boxes(m))

        with ThreadPoolExecutor() as ex:
            tuple(ex.map(idle, boxes))
    except Exception as e:
        getLogger().exception("%s", e)
        raise


with nullcontext():
    captureWarnings(True)
    basicConfig(format="%(message)s", level=INFO)

    if system() == "Darwin":

        class _SysLogHandler(SysLogHandler):
            def emit(self, record: LogRecord) -> None:
                try:
                    pri = self.encodePriority(
                        self.facility,
                        self.mapPriority(record.levelname),
                    )
                    msg = self.format(record)
                except Exception:
                    self.handleError(record)
                else:
                    syslog(pri, msg)

        openlog(ident=_FILE.name, facility=LOG_MAIL)
        getLogger().addHandler(_SysLogHandler(facility=LOG_MAIL))


try:
    main()
except KeyboardInterrupt:
    exit(130)
