#!/usr/bin/env -S -- perl -CASD

use Carp;
use Config;
use English;
use File::Basename;
use File::Copy;
use File::Spec::Functions;
use File::Temp qw( tempdir );
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

if ( !-d $lib ) {
  my $perl_libd = catfile( $tmp, 'perl' );
  my $tar_libd  = catfile( $tmp, 'lib' );
  my @perl_libs = qw( YAML::Tiny File::HomeDir Unicode::GCString );
  my $tmp_lib   = tempdir( DIR => $tmp );

  $ENV{HOME}                = $perl_libd;
  $ENV{PERL_LOCAL_LIB_ROOT} = $perl_libd;
  $ENV{PERL_MB_OPT}         = "--install_base $perl_libd";
  $ENV{PERL_MM_OPT}         = "INSTALL_BASE=$perl_libd";
  $ENV{PERL5LIB}            = catfile( $perl_libd, 'lib', 'perl5' );

  my $repo = 'cmhughes/latexindent.pl';
  my $tag  = `gh-latest.sh . '$repo'`;
  $CHILD_ERROR == 0 or croak $CHILD_ERROR;

  my $uri      = "https://github.com/$repo/archive/refs/tags/$tag.tar.gz";
  my $filename = `get.sh '$uri'`;
  $CHILD_ERROR == 0 or croak $CHILD_ERROR;

  system( 'unpack.sh', $tmp_lib, $filename ) == 0 or croak $CHILD_ERROR;

  exit;

  my @chronic = system( 'which', '--', 'chronic' ) ? () : qw( chronic -- );
  system( @chronic, $cpan, '-T', '-I', '-i', @perl_libs ) == 0
    or croak $CHILD_ERROR;

  my @globbed = glob "\Q$tmp_lib\E/*";
  for my $source (@globbed) {
    move( $source, $tar_libd ) or croak $ERRNO;
  }
  rmdir $tmp_lib;
  move( $tmp, $lib ) or croak $ERRNO;
}
