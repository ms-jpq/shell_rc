#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from contextlib import suppress
from http import HTTPStatus
from http.server import CGIHTTPRequestHandler, ThreadingHTTPServer
from pathlib import PurePosixPath
from posixpath import normpath, sep
from socket import IPPROTO_IPV6, IPV6_V6ONLY, AddressFamily, getfqdn
from socketserver import TCPServer
from sys import stderr
from typing import Any
from urllib.parse import urlsplit
from webbrowser import open

_POSIX_ROOT = PurePosixPath(sep)
_CGI_SCRIPT = _POSIX_ROOT / "cgi-bin" / "gitweb.cgi"


def _path(Handler: CGIHTTPRequestHandler) -> PurePosixPath:
    return PurePosixPath(urlsplit(Handler.path).path)


def _redirect(handler: CGIHTTPRequestHandler) -> bool:
    if _path(handler) == _POSIX_ROOT:
        handler.send_response_only(HTTPStatus.SEE_OTHER)
        handler.send_header("Location", normpath(_CGI_SCRIPT))
        handler.end_headers()
        return True
    else:
        return False


def _rewrite(handler: CGIHTTPRequestHandler) -> None:
    if _path(handler) == _POSIX_ROOT:
        handler.path = normpath(_POSIX_ROOT)


class _Handler(CGIHTTPRequestHandler):
    def is_cgi(self) -> bool:
        return _path(self).is_relative_to(_CGI_SCRIPT) and super().is_cgi()

    def do_HEAD(self) -> None:
        if not _redirect(self):
            _rewrite(self)
            super().do_HEAD()

    def do_GET(self) -> None:
        if not _redirect(self):
            _rewrite(self)
            super().do_GET()

    def do_POST(self) -> None:
        if not _redirect(self):
            _rewrite(self)
            super().do_POST()

    def log_message(self, format: str, *args: Any) -> None:
        ...


class _Server(ThreadingHTTPServer):
    address_family = AddressFamily.AF_INET6
    allow_reuse_address = True
    allow_reuse_port = True

    def server_bind(self) -> None:
        self.socket.setsockopt(IPPROTO_IPV6, IPV6_V6ONLY, 0)
        TCPServer.server_bind(self)
        _, server_port, *_ = self.socket.getsockname()
        self.server_name = getfqdn()
        self.server_port = server_port


with suppress(KeyboardInterrupt):
    srv = _Server(("", 0), _Handler)
    addr = f"http://{srv.server_name}:{srv.server_port}"
    open(addr)
    print(addr, file=stderr)
    srv.serve_forever()
