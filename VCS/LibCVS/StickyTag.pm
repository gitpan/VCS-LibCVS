#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::StickyTag;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::StickyTag - A sticky tag across the repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

A Sticky which is chosen by a non-branch tag.

=head1 SUPERCLASS

VCS::LibCVS::Sticky

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/StickyTag.pm,v 1.4 2003/06/27 20:52:32 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Sticky");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Repository} VCS::LibCVS::Repository
# $self->{Tag}        string scalar

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$sticky_tag = VCS::LibCVS::StickyTag->new($repository, $tag)

=over 4

=item return type: VCS::LibCVS::StickyTag

=item argument 1 type: VCS::LibCVS::Repository

=item argument 2 type: string scalar

=back

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;
  ($that->{Repository}, $that->{Tag}) = @_;
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

=head2 B<get_tag()>

$tag = $entry->get_tag()

=over 4

=item return type: string scalar

=back

Returns the tag string for this sticky tag

=cut

sub get_tag {
  my $self = shift;
  return $self->{Tag};
}


###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
