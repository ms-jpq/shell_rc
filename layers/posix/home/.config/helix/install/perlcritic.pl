#!/usr/bin/env -S -- PERL_UNICODE=ASD perl

use Carp;
use Config;
use English;
use File::Basename;
use File::Copy;
use File::Spec::Functions;
use autodie;
use strict;
use utf8;
use warnings FATAL => 'all';

my $tmp  = $ENV{RUN};
my $cpan = catfile( dirname( $Config{perlpath} ), 'cpan' );
my $lib  = $ENV{LIB};

if ( $OSNAME eq 'MSWin32' ) {
  $cpan = "$cpan.bat";
}

if ( !-x $cpan ) {
  exit;
}

if ( $ENV{CI} ) {
  exit;
}

if ( !-d $lib ) {

  $ENV{HOME}                = $tmp;
  $ENV{PERL_LOCAL_LIB_ROOT} = $tmp;
  $ENV{PERL_MB_OPT}         = "--install_base $tmp";
  $ENV{PERL_MM_OPT}         = "INSTALL_BASE=$tmp";
  $ENV{PERL_MM_USE_DEFAULT} = 1;
  $ENV{PERL5LIB}            = catfile( $tmp, 'lib', 'perl5' );

  my @chronic = system( 'which', '--', 'chronic' ) ? () : qw( chronic -- );
  system( @chronic, $cpan, '-T', '-i', qw( Perl::Critic Perl::Tidy ) ) == 0
    or croak $CHILD_ERROR;

  move( $tmp, $lib ) or croak $ERRNO;
}
