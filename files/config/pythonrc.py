#!/usr/bin/env python3

import readline
from atexit import register
from os import R_OK, access, environ
from os.path import isfile, join
from pprint import pprint

__history_file__ = join(environ["XDG_CACHE_HOME"], "python_hist")
__readline_write_history__ = readline.write_history_file

readline.write_history_file = lambda *args: None

if isfile(__history_file__) and access(__history_file__, R_OK):
    readline.read_history_file(__history_file__)

register(__readline_write_history__, __history_file__)
