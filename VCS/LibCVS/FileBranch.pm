#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::FileBranch;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::FileBranch - A specific branch of a file managed by CVS.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a single branch of a file managed by CVS.

Branches are identified by revision numbers, but most have branch tags in
addition.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/FileBranch.pm,v 1.7 2003/06/27 20:52:32 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{File}            VCS::LibCVS::RepositoryFile of this FileBranch
# $self->{TagSpec}         VCS::LibCVS::Datum::TagSpec of the FileBranch
#                          It's undef for the main branch/trunk
# $self->{RevisionNumber}  VCS::LibCVS::Datum::RevisionNumber of this FileBranch

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$file_branch = VCS::LibCVS::FileBranch->new($file, $tag_spec, $revision)

=over 4

=item return type: VCS::LibCVS::FileBranch

=item argument 1 type: VCS::LibCVS::RepositoryFile

=item argument 2 type: VCS::LibCVS::Datum::TagSpec

=item argument 3 type: VCS::LibCVS::Datum::RevisionNumber

=back

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;

  ($that->{File}, $that->{TagSpec}, $that->{RevisionNumber}) = @_;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_revision_number()>

$file = $file_branch->get_revision_number()

=over 4

=item return type: VCS::LibCVS::RevisionNumber

=back

=cut

sub get_revision_number() {
  return shift->{RevisionNumber};
}

=head2 B<get_file()>

$file = $file_branch->get_file()

=over 4

=item return type: VCS::LibCVS::RepositoryFile

=back

=cut

sub get_file() {
  return shift->{File};
}

=head2 B<get_tag()>

$tag = $file_branch->get_tag()

=over 4

=item return type: VCS::LibCVS::Datum::TagSpec

=back

=cut

sub get_tag() {
  return shift->{TagSpec};
}

=head2 B<get_tip_revision()>

$file_rev = $file_branch->get_tip_revision()

=over 4

=item return type: VCS::LibCVS::FileRevision

=back

Return the latest revision (the tip) of the branch.

=cut

sub get_tip_revision() {
  my $self = shift;
  my $log = $self->{File}->_get_log_messages();

  # The log messages are an indication of all the revisions of the file.  We go
  # through them all, and find the latest one on this branch
  my $tip_num = $self->{RevisionNumber};
  foreach my $rev_str (keys %$log) {
    my $rev = VCS::LibCVS::Datum::RevisionNumber->new($rev_str);
    # Only compare revision numbers on this branch.
    if ($rev->branch_of()->equals($self->{RevisionNumber})) {
      if (   $tip_num->compare($rev)
          == VCS::LibCVS::Datum::RevisionNumber::COMPARE_GREATER) {
        $tip_num = $rev;
      }
    }
  }
  return VCS::LibCVS::FileRevision->new($self->{File}, $tip_num);
}

###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
