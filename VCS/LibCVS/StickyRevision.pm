#
# Copyright 2004 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::StickyRevision;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::StickyRevision - A sticky revision across the repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

A Sticky which is specified by a revision number.

=head1 SUPERCLASS

VCS::LibCVS::Sticky

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/StickyRevision.pm,v 1.1 2004/03/22 00:19:01 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Sticky");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Repository} VCS::LibCVS::Repository
# $self->{Revision}   string scalar

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$sticky_revision = VCS::LibCVS::StickyRevision->new($repository, $revision)

=over 4

=item return type: VCS::LibCVS::StickyRevision

=item argument 1 type: VCS::LibCVS::Repository

=item argument 2 type: string scalar

=back

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;
  ($that->{Repository}, $that->{Revision}) = @_;
  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_repository()>

$tag = $sticky_tag->get_repository()

=over 4

=item return type: VCS::LibCVS::Repository

=back

Returns the repository for this sticky tag

=cut

sub get_repository {
  my $self = shift;
  return $self->{Repository};
}

=head2 B<get_revision()>

$revision = $sticky->get_revision()

=over 4

=item return type: string scalar

=back

Returns the revision number for this sticky revision

=cut

sub get_revision {
  my $self = shift;
  return $self->{Revision};
}


###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
