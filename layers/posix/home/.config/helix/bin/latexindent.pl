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
my $lib = catfile( $dir, '..', '..', 'latexindent.pl', 'lib' );

$ENV{PERL5LIB} = catfile( $lib, 'perl', 'lib', 'perl5' );
exec 'perl', catfile( $lib, 'lib', 'latexindent.pl' ), @ARGV or croak $ERRNO;
