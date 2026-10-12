#!/usr/bin/env -S -- PERL_UNICODE=ASD perl

use Carp;
use English;
use File::Basename;
use File::Spec::Functions;
use autodie;
use strict;
use utf8;
use warnings FATAL => 'all';

my $dir = dirname(__FILE__);
my $lib = catfile( $dir, '..', '..', 'perlcritic.pl', 'lib' );

$ENV{PERL5LIB} = catfile( $lib, 'lib', 'perl5' );

exec 'perl', catfile( $lib, 'bin', 'perltidy' ),
  qw( --standard-error-output --standard-output --indent-columns=2 --output-line-ending=unix ),
  @ARGV
  or croak $ERRNO;
