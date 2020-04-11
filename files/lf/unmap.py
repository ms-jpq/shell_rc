#!/usr/bin/env python3

import re


cmds1 = """\
up                       (default 'k' and '<up>')
half-up                  (default '<c-u>')
page-up                  (default '<c-b>' and '<pgup>')
down                     (default 'j' and '<down>')
half-down                (default '<c-d>')
page-down                (default '<c-f>' and '<pgdn>')
updir                    (default 'h' and '<left>')
open                     (default 'l' and '<right>')
quit                     (default 'q')
top                      (default 'gg' and '<home>')
bottom                   (default 'G' and '<end>')
toggle                   (default '<space>')
invert                   (default 'v')
unselect                 (default 'u')
copy                     (default 'y')
cut                      (default 'd')
paste                    (default 'p')
clear                    (default 'c')
redraw                   (default '<c-l>')
reload                   (default '<c-r>')
read                     (default ':')
rename                   (default 'r')
shell                    (default '$')
shell-pipe               (default '%')
shell-wait               (default '!')
shell-async              (default '&')
find                     (default 'f')
find-back                (default 'F')
find-next                (default ';')
find-prev                (default ',')
search                   (default '/')
search-back              (default '?')
search-next              (default 'n')
search-prev              (default 'N')
mark-save                (default 'm')
mark-load                (default "'")
mark-remove              (default `"`)
"""

cmds2 = """\
cmd-escape               (default '<esc>')
cmd-complete             (default '<tab>')
cmd-enter                (default '<c-j>' and '<enter>')
cmd-history-next         (default '<c-n>')
cmd-history-prev         (default '<c-p>')
cmd-delete               (default '<c-d>' and '<delete>')
cmd-delete-back          (default '<bs>' and '<bs2>')
cmd-left                 (default '<c-b>' and '<left>')
cmd-right                (default '<c-f>' and '<right>')
cmd-home                 (default '<c-a>' and '<home>')
cmd-end                  (default '<c-e>' and '<end>')
cmd-delete-home          (default '<c-u>')
cmd-delete-end           (default '<c-k>')
cmd-delete-unix-word     (default '<c-w>')
cmd-yank                 (default '<c-y>')
cmd-transpose            (default '<c-t>')
cmd-interrupt            (default '<c-c>')
cmd-word                 (default '<a-f>')
cmd-word-back            (default '<a-b>')
cmd-capitalize-word      (default '<a-c>')
cmd-delete-word          (default '<a-d>')
cmd-uppercase-word       (default '<a-u>')
cmd-lowercase-word       (default '<a-l>')
cmd-transpose-word       (default '<a-t>')
"""

cmds3 = """\
map zh set hidden!
map zr set reverse!
map zn set info
map zs set info size
map zt set info time
map za set info size:time
map sn :set sortby natural; set info
map ss :set sortby size; set info size
map st :set sortby time; set info time
map sa :set sortby atime; set info atime
map sc :set sortby ctime; set info ctime
map se :set sortby ext; set info
map gh cd ~
"""



def parse_unquotes():
  c1_1 = "map '"
  c1_2 = 'map "'
  return [c1_1, c1_2]


def parse_quotes(lines):
  m = re.findall("'[^\']+'", lines)
  l = ["map " + s.strip("'")
       for s in m
       if s]
  return l


def p_cmds12():
  c_ = parse_unquotes()
  c1 = parse_quotes(cmds1)
  c2 = parse_quotes(cmds2)
  c12 = [*c_, *c1, *c2]
  return c12


def p_cmds3():
  c3 = re.findall("map [^ ]+", cmds3)
  return c3


c_all = [*p_cmds12(), *p_cmds3()]

for c in c_all:
  print(c)
