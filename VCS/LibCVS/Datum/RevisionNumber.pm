#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::RevisionNumber;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::RevisionNumber - A CVS revision number.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a CVS revision number, either a branch or regular one.

It accepts both regular branch numbers (1.4.2) and magic ones (1.4.0.2).  This
means that numbers of the form "0.x" are ambiguous.  They are treated as
revision numbers on the branch "0".

The revision number "0" is used for added files, as well as for one of the
trunk branches.

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Datum/RevisionNumber.pm,v 1.9 2003/06/27 20:52:33 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Datum");

# COMPARE_* constants are documented in compare() routine
use constant COMPARE_EQUAL => 0;
use constant COMPARE_LESS => 1;
use constant COMPARE_GREATER => 2;
use constant COMPARE_INCOMPARABLE => 3;

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Number} is the number as a string, magic branch numbers are converted
#                 to regular branch numbers.
# $self->{IsBranch} true if it's a branch revision number

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$rev_num = VCS::LibCVS::Datum::RevisionNumber->new("1.2.4.5")
$rev_num = VCS::LibCVS::Datum::RevisionNumber->new("1.2.0.4")
$rev_num = VCS::LibCVS::Datum::RevisionNumber->new("1.2.4")

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=item argument 1 type: scalar string

Must be a valid CVS revision number.

=back

=cut

sub new {
  my ($class, $num) = @_;
  my $that = bless {}, $class;

  # 0 may only appear by itself, or as the first field or the second to last
  confess "Bad revision number $num"
    unless ($num =~ /^0$|^(0\.)?([1-9][0-9]*\.)*(0\.)?[1-9][0-9]*$/);

  # Convert magic branch numbers to regular ones by removing the 0 in the
  # second to last place, unless it's the first number.
  $num =~ s/\.0(\.[0-9])*$/$1/;

  # It's a branch if there are an odd number of fields
  $that->{IsBranch} = ((my @t = split(/\./, "$num")) % 2);
  $that->{Number} = $num;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<as_string()>

$rev_str = $rev_num->as_string()

=over 4

=item return type: string scalar

=back

Returns the revision number as a string.

=cut

sub as_string {
  my $self = shift;
  return $self->{Number};
}

=head2 B<equals()>

if ($rev_num1->equals($rev_num2)) {

=over 4

=item return type: boolean

=item argument 1 type: VCS::LibCVS::Datum::RevisionNumber

=back

Returns true if the revision numbers contain the same information.

=cut

sub equals {
  my $self = shift;
  return 0 unless $self->SUPER::equals(@_);
  my $other = shift;
  return $self->{Number} eq $other->{Number};
}

=head2 B<is_branch()>

if ($rev_num->is_branch()) { . . .

=over 4

=item return type: boolean scalar

=back

Return true if this is a branch revision number, false otherwise.

=cut

sub is_branch {
  my $self = shift;
  return $self->{IsBranch};
}

=head2 B<is_trunk()>

if ($rev_num->is_trunk()) { . . .

=over 4

=item return type: boolean scalar

=back

Return true if this is a revision number for the trunk, false otherwise.
A trunk revision number is one with only one field, like: "1", "2", . . .

=cut

sub is_trunk {
  my $self = shift;
  return ($self->_depth() == 1);
}

=head2 B<branch_of()>

$branch_num = $rev_num->branch_of()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

Get the RevisionNumber for the branch on which this revision lives.  If it's a
branch revision number it throws an exception.

=cut

sub branch_of {
  my $self = shift;
  confess "No branch_of() for a branch RevisionNumber" if $self->is_branch();
  return $self->_subrevision();
}

=head2 B<base_of()>

$branch_num = $rev_num->base_of()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

Returns the RevisionNumber from which this branch starts.  If it's not a branch
revision, or if it's the main branch an exception is thrown.

=cut

sub base_of {
  my $self = shift;
  confess "Only branch revisions have a base" unless $self->is_branch();
  confess "Main branch has no base" if $self->{Number} =~ /^[0-9]+$/;
  return $self->_subrevision();
}

=head2 B<compare()>

$diff = $rev_num1->compare($rev_num2)

=over 4

=item return type: integer, one of VCS::LibCVS::Datum::RevisionNumber::COMPARE_*

=item argument 1 type: string or RevisionNumber object

=back

Compares this revision number with the argument.

The meanings of the return values are:

=over 4

=item COMPARE_EQUAL

They are the same revision number.

=item COMPARE_LESS

The argument is less than this.

=item COMPARE_GREATER

The argument is greater than this.

=item COMPARE_INCOMPARABLE

This and the argument are incomparable.

=back

Both branch and regular revision numbers can be compared this way.  A branch
revision number is less than all revisions on it (except its base revision) and
its subbranches.  So 1.6.2 is greater than 1.6, less than 1.6.2.4, and
incomparable with 1.7.

It would be nice if 1.6.2 were less than 1.6, since it's on the branch, but
then we'd lose transitivity, since 1.6.2 < 1.6, 1.6 < 1.7, but 1.6.2 and 1.7
are incomparable.

=cut

sub compare {
  my ($self, $other) = @_;

  if (!ref($other)) {
    $other = new VCS::LibCVS::Datum::RevisionNumber($other);
  }

  # Check revision numbers that are of the same depth.
  # Since they are of the same depth, they are either both branches, or both
  # revisions
  if ($self->_depth() == $other->_depth()) {
    # Check for trivial equality
    if ($self->as_string() eq ($other->as_string)) {
      return COMPARE_EQUAL;
    }
    # Branches of the same depth that aren't equal are incomparable
    if ($self->is_branch()) {
      return COMPARE_INCOMPARABLE;
    }
    # For revisions, check that they are on the same branch, then check their
    # last field
    if ($self->branch_of()->compare($other->branch_of) == COMPARE_EQUAL) {
      return ($other->_last_field > $self->_last_field)
        ? COMPARE_GREATER : COMPARE_LESS;
    }
    # They are revisions on different branches
    return COMPARE_INCOMPARABLE;
  }

  # The revision numbers are of different depths

  # Reduce the deep revision to the same depth as the shallow revision, and
  # then compare them.
  my $shallow_rev = ($self->_depth > $other->_depth) ? $other : $self;
  my $deep_rev = ($self->_depth > $other->_depth) ? $self : $other;
  my $less_deep_rev = $deep_rev;
  while ($shallow_rev->_depth() != $less_deep_rev->_depth()) {
    $less_deep_rev = $less_deep_rev->_subrevision();
  }

  # Compare the revisions, and then change the result to be correct for
  # $shallow_rev->compare($deep_rev)
  my $result = $shallow_rev->compare($less_deep_rev);

  # eg $shallow_rev is 1.6, $deep_rev is 1.6.4.3
  $result = COMPARE_GREATER if ($result == COMPARE_EQUAL);

  # eg $shallow_rev is 1.4, $deep_rev is 1.6.4.3
  $result = COMPARE_GREATER if ($result == COMPARE_GREATER);

  # eg $shallow_rev is 1.8, $deep_rev is 1.6.4.3
  $result = COMPARE_INCOMPARABLE if ($result == COMPARE_LESS);

  $result = COMPARE_INCOMPARABLE if ($result == COMPARE_INCOMPARABLE);

  # Switch GREATER to LESS if we did our compare the wrong way
  if (($self->_depth > $other->_depth) && $result == COMPARE_GREATER) {
    $result = COMPARE_LESS;
  }
  return $result;
}

###############################################################################
# Private routines
###############################################################################

# Used by branch_of and base_of, create new revision number with one less field
sub _subrevision {
  my $self = shift;
  my ($sub_num) = ($self->{Number} =~ /^(.*)\.[0-9]+$/);
  return VCS::LibCVS::Datum::RevisionNumber->new($sub_num);
}

# Get the depth of the revision, the number of fields.
sub _depth {
  my $self = shift;
  my $depth = (my @t = split(/\./, "$self->{Number}"));
  return $depth;
}

# The last field of this revision number
sub _last_field {
  my $self = shift;
  my ($self_field) = ($self->{Number} =~ /.*\.([0-9]+)/);
  return $self_field;
}

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
