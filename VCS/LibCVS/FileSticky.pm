#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::FileSticky;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::FileSticky - A sticky data referenced file revision.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a single revision of a file managed by CVS, as indexed by a sticky,
either a date or a non-branch tag.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/FileSticky.pm,v 1.3 2003/06/27 20:52:32 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{FileRevision}     VCS::LibCVS::FileRevision of this sticky
# $self->{Sticky}           VCS::LibCVS::Sticky the sticky data

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$file_sticky = VCS::LibCVS::FileSticky->new($file_revision, $sticky)

=over 4

=item return type: VCS::LibCVS::FileSticky

=item argument 1 type: VCS::LibCVS::FileRevision

=item argument 2 type: VCS::LibCVS::Sticky

=back

=cut

sub new {
  my $class = shift;
  my ($file_revision, $sticky) = @_;
  my $that = bless {}, $class;

  $that->{FileRevision} = $file_revision;
  $that->{Sticky} = $sticky;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_file_revision()>

$file_rev = $file_sticky->get_file_revision()

=over 4

=item return type: VCS::LibCVS::FileRevision

=back

=cut

sub get_file_revision() {
  return shift->{FileRevision};
}

=head2 B<get_sticky()>

$sticky = $file_sticky->get_sticky()

=over 4

=item return type: VCS::LibCVS::Sticky

=back

=cut

sub get_sticky() {
  return shift->{Sticky};
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
