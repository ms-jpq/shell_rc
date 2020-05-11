#!/usr/bin/env python3

import readline
import os
from pprint import pprint

__history_file__ = os.path.join(os.environ["XDG_CACHE_HOME"], "python_hist")
__readline_write_history__ = readline.write_history_file

readline.write_history_file = lambda *args: __readline_write_history__(
    __history_file__)
if os.path.isfile(__history_file__) and os.access(__history_file__, os.R_OK):
  readline.read_history_file(__history_file__)
