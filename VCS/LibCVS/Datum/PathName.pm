#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::PathName;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::PathName - A CVS datum for a CVS pathname

=head1 SYNOPSIS

  $string = VCS::LibCVS::Datum::PathName->new(["adir","/home/cvs/adir/file"]);

=head1 DESCRIPTION

A CVS Pathname, used in CVS responses.  It consists of a local directory name
and a repository filename.  See the cvsclient docs for more info.

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Datum/PathName.pm,v 1.5 2003/06/27 20:52:33 dissent Exp $ ';

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

sub _data_names { return ("LocalDirectory", "RemoteFile"); }

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
