from __future__ import annotations

import abc
import argparse
import array
import ast
import asyncio
import atexit
import base64
import bisect
import builtins
import calendar
import cmath
import cmd
import collections
import colorsys
import concurrent
import concurrent.futures
import configparser
import contextlib
import contextvars
import cProfile
import csv
import ctypes
import dataclasses
import datetime as dt
import decimal
import difflib
import email
import encodings
import enum
import errno
import filecmp
import fnmatch as fn_match
import fractions
import functools
import gc
import getpass
import glob
import graphlib
import hashlib
import hmac
import html
import http
import importlib
import inspect
import io
import ipaddress
import itertools
import json
import locale
import logging
import math
import mimetypes
import multiprocessing
import ntpath
import numbers
import operator
import os
import pathlib
import pdb
import platform
import posixpath
import pprint as pp
import queue
import random as rand
import re
import sched
import secrets
import shlex
import shutil
import signal
import socket
import sqlite3
import stat as os_stat
import statistics
import string
import subprocess
import sys
import sysconfig
import tempfile
import textwrap
import threading
import time
import trace
import traceback
import types
import typing
import unicodedata
import urllib
import uuid
import weakref
import webbrowser
import xml
from argparse import ArgumentError, ArgumentParser, Namespace
from asyncio import all_tasks, tasks
from asyncio.tasks import create_task, gather
from base64 import b64decode, b64encode
from collections import ChainMap, Counter, defaultdict, deque
from collections.abc import (
    AsyncGenerator,
    AsyncIterable,
    AsyncIterator,
    Awaitable,
    ByteString,
    Callable,
    Collection,
    Container,
    Coroutine,
    Generator,
    Hashable,
    ItemsView,
    Iterable,
    Iterator,
    KeysView,
    Mapping,
    MappingView,
    MutableMapping,
    MutableSequence,
    MutableSet,
    Reversible,
    Sequence,
    Set,
    Sized,
    ValuesView,
)
from concurrent.futures import ThreadPoolExecutor
from configparser import RawConfigParser
from contextlib import (
    AbstractAsyncContextManager,
    AbstractContextManager,
    closing,
    nullcontext,
    suppress,
)
from csv import DictReader, DictWriter
from dataclasses import dataclass, is_dataclass
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from encodings import idna
from enum import Enum, IntEnum, IntFlag, auto, unique
from fnmatch import fnmatch, fnmatchcase
from fractions import Fraction
from functools import cache, lru_cache, partial, reduce
from hashlib import blake2b, blake2s, md5, sha1, sha256, sha512
from http import cookiejar, cookies
from importlib import import_module
from inspect import getmembers
from io import BytesIO, StringIO
from ipaddress import (
    AddressValueError,
    IPv4Address,
    IPv4Interface,
    IPv4Network,
    IPv6Address,
    IPv6Interface,
    IPv6Network,
    NetmaskValueError,
    collapse_addresses,
    ip_address,
    ip_interface,
    ip_network,
    summarize_address_range,
)
from itertools import (
    accumulate,
    chain,
    combinations,
    combinations_with_replacement,
    compress,
    count,
    cycle,
    dropwhile,
    filterfalse,
    groupby,
    islice,
    permutations,
    product,
    repeat,
    starmap,
    takewhile,
    tee,
    zip_longest,
)
from locale import getlocale, getpreferredencoding, normalize, strxfrm
from logging import getLogger
from math import factorial, inf, nan
from multiprocessing import cpu_count
from os import (
    PathLike,
    chdir,
    environ,
    getcwd,
    linesep,
    makedirs,
    path,
    renames,
    stat,
    walk,
)
from os.path import (
    abspath,
    altsep,
    basename,
    commonpath,
    commonprefix,
    curdir,
    devnull,
    dirname,
    exists,
    expanduser,
    expandvars,
    extsep,
    getatime,
    getctime,
    getmtime,
    getsize,
    isabs,
    isdir,
    isfile,
    islink,
    ismount,
    join,
    lexists,
    normcase,
    normpath,
    pardir,
    pathsep,
    realpath,
    relpath,
    sep,
    splitdrive,
    splitext,
    supports_unicode_filenames,
)
from pathlib import Path, PurePath, PurePosixPath, PureWindowsPath
from platform import uname
from pprint import pprint
from queue import SimpleQueue
from random import (
    choice,
    choices,
    randbytes,
    randint,
    random,
    randrange,
    sample,
    shuffle,
)
from re import compile, findall, finditer, match, search, split, sub, subn
from shlex import quote
from shutil import (
    chown,
    copy2,
    copystat,
    copytree,
    get_terminal_size,
    ignore_patterns,
    make_archive,
    move,
    rmtree,
    unpack_archive,
    which,
)
from signal import Signals
from socket import AddressFamily, AddressInfo, getfqdn, has_dualstack_ipv6
from statistics import mean, median, mode, stdev, variance
from string import (
    Template,
    ascii_letters,
    ascii_lowercase,
    ascii_uppercase,
    capwords,
    digits,
    hexdigits,
    octdigits,
    printable,
    punctuation,
    whitespace,
)
from subprocess import CalledProcessError, CompletedProcess, check_call, check_output
from sys import argv, executable, exit, stderr, stdin, stdout
from tempfile import (
    NamedTemporaryFile,
    SpooledTemporaryFile,
    TemporaryDirectory,
    TemporaryFile,
    gettempdir,
    mkdtemp,
    mkstemp,
)
from textwrap import dedent
from threading import Thread, ThreadError
from time import monotonic, sleep
from typing import (
    IO,
    Annotated,
    Any,
    AnyStr,
    BinaryIO,
    ClassVar,
    Final,
    Generic,
    Literal,
    NewType,
    NoReturn,
    Optional,
    Protocol,
    TextIO,
    TypedDict,
    TypeVar,
    Union,
    cast,
    overload,
    runtime_checkable,
)
from urllib import parse, request
from urllib.parse import urlencode, urlsplit, urlunsplit
from uuid import UUID, uuid1, uuid3, uuid4, uuid5
from weakref import WeakKeyDictionary, WeakSet, WeakValueDictionary

if sys.version_info >= (3, 10):
    from contextlib import aclosing
    from itertools import pairwise
    from typing import (
        Concatenate,
        NamedTuple,
        ParamSpec,
        ParamSpecArgs,
        ParamSpecKwargs,
        TypeAlias,
        TypeGuard,
    )


if sys.version_info >= (3, 11):
    import tomllib
    from typing import (
        LiteralString,
        Never,
        NotRequired,
        Required,
        Self,
        TypeVarTuple,
        Unpack,
        assert_never,
        assert_type,
        dataclass_transform,
        reveal_type,
    )


def __init() -> None:
    import readline

    rh = readline.read_history_file
    wh = readline.write_history_file

    hist = join(environ["XDG_STATE_HOME"], "shell_history", "python")

    def read_history_file(_: Union[str, bytes, PathLike, None] = None) -> None:
        rh(hist)

    def write_history_file(_: Union[str, bytes, PathLike, None] = None) -> None:
        wh(hist)

    readline.read_history_file = read_history_file
    readline.write_history_file = write_history_file

    with suppress(AttributeError):
        ah = readline.append_history_file

        def append_history_file(
            __n: int, _: Union[str, bytes, PathLike, None] = None
        ) -> None:
            ah(__n, hist)

        readline.append_history_file = append_history_file


__init()
del __init


def clear() -> None:
    check_call(("clear",))
