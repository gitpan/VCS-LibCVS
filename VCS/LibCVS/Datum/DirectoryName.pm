#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::DirectoryName;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::DirectoryName - A CVS datum for the name of a directory

=head1 SYNOPSIS

  $string = VCS::LibCVS::Datum::DirectoryName->new("/home/cvs/dir");

=head1 DESCRIPTION

The name of a directory.

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Datum/DirectoryName.pm,v 1.5 2003/06/27 20:52:33 dissent Exp $ ';

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

sub _data_names { return ("DirectoryName"); }

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
