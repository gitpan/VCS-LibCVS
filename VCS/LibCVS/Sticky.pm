#
# Copyright 2003,2004 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Sticky;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Sticky - A bit of sticky info across the repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a bit of sticky info across the repository.  There's not much reason
to create this class itself, instead you should use its subclasses.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Sticky.pm,v 1.4 2004/08/27 03:49:09 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=cut

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=cut

###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
