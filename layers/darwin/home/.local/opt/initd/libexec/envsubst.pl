#!/usr/bin/env -S -- PERL_UNICODE=ASD perl

use Carp;
use English;
use autodie;
use strict;
use utf8;
use warnings FATAL => 'all';

while (<>) {
  s{\$(\{)?(\w+)(?(1)\})} {$ENV{$2} // $MATCH}ge;
}
continue {
  print or croak $ERRNO;
}
