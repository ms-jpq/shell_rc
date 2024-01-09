#!/usr/bin/env -S -- perl -CASD -w

use English;
use autodie;
use strict;
use utf8;

while (<>) {
  s{\$(\{)?(\w+)(?(1)\})} {$ENV{$2} // $MATCH}ge;
}
continue {
  print or croak $ERRNO;
}
