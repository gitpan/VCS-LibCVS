#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::Time;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::Time - A CVS datum for a time

=head1 SYNOPSIS

  $string = VCS::LibCVS::Datum::Time->new("Mon Dec 16 16:49:16 2002");

=head1 DESCRIPTION

A time in CVS format.

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

# Should use a date class.  See [Issue 22].

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Datum/Time.pm,v 1.6 2003/06/27 20:52:33 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Datum");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

###############################################################################
# Class routines
###############################################################################

###############################################################################
# Instance routines
###############################################################################

###############################################################################
# Private routines
###############################################################################

sub _data_names { return ("Time"); }

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
