#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::WorkingFile;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::WorkingFile - A file checked out of CVS.

=head1 SYNOPSIS

=head1 DESCRIPTION

This object represents a local copy of a file checked out from CVS.

=head1 SUPERCLASS

VCS::LibCVS::WorkingFileOrDirectory

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/WorkingFile.pm,v 1.7 2003/06/27 20:52:32 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::WorkingFileOrDirectory");

# ACTION_* constants are documented in the get_scheduled_action routine
use constant ACTION_NONE    => 0;
use constant ACTION_ADD     => 1;
use constant ACTION_REMOVE  => 2;

# STATE_* constants are documented in the get_state routine
use constant STATE_UPTODATE       => 0;
use constant STATE_MODIFIED       => 1;
use constant STATE_HADCONFLICTS   => 2;
use constant STATE_ABSENT         => 3;

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Entry}  VCS::LibCVS::Datum::Entry for this file, from the Admin dir

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$working_file = VCS::LibCVS::WorkingFile->new($filename)

=over 4

=item return type: VCS::LibCVS::WorkingFile

=item argument 1 type: scalar string

The name of the file which is under CVS control.

=back

Creates a new WorkingFile.  The filename may be relative or absolute, and is
stored as such.

It throws an exception if the file is not recorded in the CVS/Entries file.

=cut

sub new {
  my $class = shift;
  my $that = $class->SUPER::new(@_);

  $that->{Admin} = VCS::LibCVS::Admin->new($that->get_name({no_base => 1}));
  $that->{Entry} = $that->{Admin}->get_Entries()->{$that->get_name({no_dir => 1})};

  confess ($that->get_name() . " is not managed by CVS") unless $that->{Entry};

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_remote_object()>

$r_file = $w_file->get_remote_object()

=over 4

=item return type: VCS::LibCVS::RepositoryFile

Returns the remote CVS file associated with this working file.

=back

It reads the CVS sandbox administrative directory to get this info.

=cut

sub get_remote_object {
  my $self = shift;

  my $repo = $self->get_repository();
  my $repo_dir = $self->{Admin}->get_Repository()->{DirectoryName};
  my $name = $self->get_name({no_dir => 1 });
  my $repo_file = File::Spec::Unix->catfile($repo_dir, $name);

  return VCS::LibCVS::RepositoryFile->new($repo, $repo_file);
}

=head2 B<get_branch()>

$branch = $w_file->get_branch()

=over 4

=item return type: VCS::LibCVS::Branch

Returns the branch this local file is on.

=back

If there is no sticky branch tag, it returns the MAIN branch.

=cut

sub get_branch {
  my $self = shift;

  my $entry_line = $self->{Entry};

  my $tag = $entry_line->get_tag();

print "^^^^^^a^: $tag\n";

#   return VCS::LibCVS::Branch->new($self->{Admin}->get_Root(),
#                                   $self->{Admin}->get_Repository(),
#                                   $self->{FileName},
#                                   $entry_line->get_tag->{TagSpec}
#                                  );
}

=head2 B<get_file_branch()>

$file_branch = $w_file->get_file_branch()

=over 4

=item return type: VCS::LibCVS::FileBranch

Returns the file branch this local file is on.

=back

The branch is determined by looking at any sticky branch tags, and then at the
revision number.

=cut

sub get_file_branch {
  my $self = shift;

  # Handle the very common case of the file being on the trunk.  It's
  # done separately because the $r_file->get_branches() routine doesn't
  # include the trunk branches: 1, 2, 3 etc.

  my $revision = $self->{Entry}->get_revision();
  my $branch_rev = $revision->branch_of();
  if ($branch_rev->is_trunk()) {
    return VCS::LibCVS::FileBranch->new($self->get_remote_object(),
                                        undef,
                                        $branch_rev);
  }

  # In order to create the FileBranch, we need both the revision number and the
  # branch tag.  Sadly, the Entries file doesn't include the branch tag in the
  # case where there is a non-branch sticky tag.  So, we get the remote file
  # and download all of the branches from the server, and search through them
  # for the right one.

  # First we search by the tag, then the revision, which takes care of the case
  # where the file is at the base revision of the branch and looking at the
  # revision number alone would lead us to the wrong branch.  (Revision 1.4
  # could be on branch 1 or branch 1.4.2.)

  my $r_file = $self->get_remote_object();
  my $all_branches = $r_file->get_branches();

  # First look for a branch with a matching tag
  my $tag = $self->{Entry}->get_tag();
  foreach my $branch (@$all_branches) {
    return $branch if $branch->get_tag()->equals($tag);
  }

  # Now look for a branch with a matching revision number
  foreach my $branch (@$all_branches) {
    return $branch if $branch->get_revision_number()->equals($branch_rev);
  }

  confess("No branch found for $self->{FullName} " . $revision->as_string());
}

=head2 B<get_directory_of()>

$w_file->get_directory_of()

=over 4

=item return type: VCS::LibCVS::WorkingDirectory

=back

Returns the working directory containing this object.  If the directory isn't
under CVS control, or if the object's specification is relative, and it's
parent directory can't be determined, an exception is thrown.

=cut

sub get_directory_of {
  my $self = shift;
  return VCS::LibCVS::WorkingDirectory->new($self->get_name({no_base => 1}));
}

=head2 B<get_scheduled_action()>

$w_file->get_scheduled_action()

=over 4

=item return type: integer, one of VCS::LibCVS::WorkingFile::ACTION_*

=back

Returns any action which has been scheduled on this file.  The actions are:

  ACTION_NONE
  ACTION_ADD
  ACTION_REMOVE

=cut

sub get_scheduled_action {
  my $self = shift;

  return ACTION_ADD if ("$self->{Entry}->{Revision}"    eq "0");
  return ACTION_REMOVE if ("$self->{Entry}->{Revision}" =~ /^-/);
  return ACTION_NONE;
}

=head2 B<get_state()>

$w_file->get_state()

=over 4

=item return type: one of VCS::LibCVS::WorkingFile::STATE_*

=back

Returns the state of the local file.  This is determined with reference to the
information in the Admin directory, including any scheduled actions.  The
possible states are:

  STATE_UPTODATE
  STATE_MODIFIED
  STATE_HADCONFLICTS
  STATE_ABSENT

In the case of a file which has been scheduled for removal, it should not
appear in the working directory, so being absent is treated as uptodate.  If it
is present, it is reported as modified.

=cut

sub get_state {
  my $self = shift;

  if ($self->get_scheduled_action() == ACTION_REMOVE) {
    return (-e $self->get_name()) ? STATE_MODIFIED : STATE_UPTODATE;
  }

  if ($self->get_scheduled_action() == ACTION_ADD) {
    return (-e $self->get_name()) ? STATE_UPTODATE : STATE_ABSENT;
  }

  if ($self->get_scheduled_action() == ACTION_NONE) {
    return STATE_ABSENT unless (-e $self->get_name());
    return STATE_HADCONFLICTS if $self->_had_conflicts();
    return ($self->_is_modified()) ? STATE_MODIFIED : STATE_UPTODATE;
  }
  confess(  "Unexpected Action: " . $self->get_scheduled_action()
          . ".  On File: " . $self->get_name());
}

=head2 B<get_rstate()>

$w_file->get_rstate()

=over 4

=item return type: one of VCS::LibCVS::WorkingFile::STATE_*

=back

Returns the state of the repository with respect to the working file info.  This
is determined with reference to the information in the Admin directory,
including any scheduled actions.  The possible states are:

  STATE_UPTODATE
  STATE_MODIFIED
  STATE_ABSENT

=cut

sub get_rstate {
  my $self = shift;

  # The remote file may not exist, and in fact shouldn't in the case of an add,
  # so wrap in an eval to catch this.
  my $remote_file;
  eval { $remote_file = $self->get_remote_object(); };
  if ($@ && ($@ !~ /cvs server: nothing known about/)) {
    confess($@);
  }

  # For newly added files, the repository state is ok ("U") unless the file is
  # already present in the repository
  if ($self->get_scheduled_action() == ACTION_ADD) {
    return ($remote_file) ? STATE_MODIFIED : STATE_UPTODATE;
  }

  # If the remote file doesn't exist, then it's missing.
  return STATE_ABSENT unless $remote_file;

  # For files that are already present in the repository, check if the tip of
  # the branch is a different revision.
  my $branch = $self->get_file_branch();
  my $tip_rev = $branch->get_tip_revision()->get_revision_number();
  my $cmp = $self->get_revision_number()->compare($tip_rev);

  return STATE_UPTODATE
    if $cmp == VCS::LibCVS::Datum::RevisionNumber::COMPARE_EQUAL;
  return STATE_MODIFIED
    if $cmp == VCS::LibCVS::Datum::RevisionNumber::COMPARE_GREATER;

  # Any other compare result is an error

  confess ("Unexpected comparison for revisions: " . $tip_rev->as_string()
           . " and " . $self->get_revision_number()->as_string());
}

=head2 B<get_revision_number()>

$w_file->get_revision_number()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

Return the revision number of the local file

=cut

sub get_revision_number {
  my $self = shift;

  return $self->{Entry}->get_revision();
}

###############################################################################
# Private routines
###############################################################################

# Consult the server to see if this file has been modified.
# Internal function for get_state()

sub _is_modified {
  my $self = shift;

  # Check file modification time, to save access in many cases
  my $updated_time = $self->{Entry}->get_updated_time();
  my $mod_time = [ $self->_stat() ]->[9];
  return 0 if ($mod_time <= $updated_time);

  # Create and issue a command to the server
  my $command = VCS::LibCVS::Command->new({}, "status", [], [$self]);
  $command->issue($self->get_repository());

  # Expect one message of the form: "File: . . . Status: . . ."
  my @st = $command->get_messages(qr/^File: .*Status: .*$/);
  confess "Bad status message for " . $self->get_name() unless (@st == 1);
  return $st[0] !~ /Up-to-date/;
}

# Consult CVS Admin files to see if the file had conflicts on merge
# Internal function for get_state()
# If it's been modified since the conflict time, assume they've been cleaned up

# perhaps it could look for the conflict markers in the file

sub _had_conflicts {
  my $self = shift;
  my $conf_time = $self->{Entry}->get_conflict_time();
  my $mod_time = [ $self->_stat() ]->[9];

  return ($mod_time <= $conf_time);
}

# Call stat on self
sub _stat {
  return stat(shift->get_name());
}

# Directory names for reporting to the server.
# Routine called in Command.pm, see there for more details.
sub _get_repo_dirs {
  my $self = shift;
  my $l_dir = $self->get_name({no_base => 1});
  my $root_repo_dir = $self->{Admin}->get_Root()->{RootDir};
  my $within_repo_dir = $self->{Admin}->get_Repository()->as_string();
  my $r_dir = File::Spec::Unix->catdir($root_repo_dir, $within_repo_dir);

  return [ $l_dir, $r_dir ];
}

# Return my entry line.  Called from Command.pm
sub _get_entry {
  my $self = shift;
  return $self->{Entry};
}

# Return my filemode.  Called from Command.pm
sub _get_mode {
  my $self = shift;
  return VCS::LibCVS::Datum::FileMode->new($self->get_name);
}

# Return my file contents.  Called from Command.pm
sub _get_contents {
  my $self = shift;
  return VCS::LibCVS::Datum::FileContents->new($self->get_name);
}

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
