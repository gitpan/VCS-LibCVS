#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::LoggingFileHandle;

use strict;
use FileHandle;

#
# A filehandle which logs everything that goes through it.
# useful for debugging protcol implementations
#

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Client/LoggingFileHandle.pm,v 1.7 2003/06/27 20:52:33 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("FileHandle");

###############################################################################
# Private variables
###############################################################################

use vars ('$NotNewLine', '%Prefix');
$NotNewLine = 0;

###############################################################################
# Class routines
###############################################################################

###############################################################################
# Instance routines
###############################################################################

# Try to prepend lines with C:
# It doesn't really work, but it's good enough
sub print {
  my $self = shift;
  if ($Prefix{$self}) {
    if (!$NotNewLine) {
      print STDERR "$Prefix{$self}";
      $NotNewLine = 1;
    }
    map { $NotNewLine = 0 if /\n/ } @_;
    print STDERR @_;
  }
  return $self->SUPER::print(@_);
}

sub getc {
  my $self = shift;
  my $char = $self->SUPER::getc();

  if ($Prefix{$self}) {
    if (!$NotNewLine) {
      print STDERR "$Prefix{$self}";
    }
    $NotNewLine = ($char ne "\n");
    print STDERR $char;
  }
  return $char;
}

sub getline {
  my $self = shift;
  my $line = $self->SUPER::getline();

  if ($Prefix{$self}) {
    if (!$NotNewLine) {
      print STDERR "$Prefix{$self}";
    }
    $NotNewLine = 0;
    print STDERR $line;
  }
  return $line;
}

# set and get the prefix to use
# if there's no prefix nothing will be logged
sub prefix {
  my ($self, $new_prefix) = @_;
  $Prefix{$self} = $new_prefix if (defined $new_prefix);
  return $Prefix{$self};
}

###############################################################################
# Private routines
###############################################################################

1;
