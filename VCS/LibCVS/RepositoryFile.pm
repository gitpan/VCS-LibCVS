#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::RepositoryFile;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::RepositoryFile - A File in the CVS repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a file in the CVS repository.

=head1 SUPERCLASS

VCS::LibCVS::RepositoryFileOrDirectory

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/RepositoryFile.pm,v 1.4 2003/06/27 20:52:32 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::RepositoryFileOrDirectory");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Tags}  A hash ref containing all the tags for this file
#                Keys are the names of tags as strings
#                Values are list refs: [ Datum::TagSpec, Datum::RevisionNumber ]
#                use _get_all_tags() to get at this
# $self->{Logs}  A hash ref containing all of the log messages for this file
#                Keys are revision numbers as strings
#                Values are Datum::LogMessage objects
#                use _get_log_messages() to get at this

###############################################################################
# Class routines
###############################################################################

sub new {
  my $class = shift;

  my $that = $class->SUPER::new(@_);

  # Do a repository action, so that the constructor will throw an exception if
  # the file doesn't exist.
  $that->_load_log_messages();

  return $that;
}


###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_tags()>

$files_tags = $cvs_file->get_tags()

=over 4

=item return type: ref to list of LibCVS::FileSticky

=back

Returns a list of all the non-branch tags on the file.

=cut

sub get_tags {
  my $self = shift;
  my @ret_tags;

  my $all_tags = $self->_get_all_tags();
  foreach my $tag (keys (%$all_tags)) {
    if (   $all_tags->{$tag}->[0]->get_type()
        eq VCS::LibCVS::Datum::TagSpec::TYPE_NONBRANCH) {
      my $sticky = VCS::LibCVS::StickyTag->new($self->{Repository},
                                               $all_tags->{$tag}->[0]->{Tag});
      my $rev = VCS::LibCVS::FileRevision->new($self, $all_tags->{$tag}->[1]);
      push @ret_tags, VCS::LibCVS::FileSticky->new($rev, $sticky);
    }
  }
  return \@ret_tags;
}

=head2 B<get_branches()>

$files_branches = $cvs_file->get_branches()

=over 4

=item return type: ref to list of VCS::LibCVS::FileBranch

=back

Returns a list of all the named branches of the file.

This will not include branches that don't have names, such as the main branch.
Doing that adds a lot more work to this routine.

=cut

sub get_branches {
  my $self = shift;
  my @ret_branches;

  my $all_tags = $self->_get_all_tags();
  foreach my $tag (keys (%$all_tags)) {
    if (   $all_tags->{$tag}->[0]->get_type()
        eq VCS::LibCVS::Datum::TagSpec::TYPE_BRANCH) {
      push @ret_branches, VCS::LibCVS::FileBranch->new($self,
                                                       $all_tags->{$tag}->[0],
                                                       $all_tags->{$tag}->[1]);
    }
  }
  return \@ret_branches;
}


=head2 B<get_revision()>

$files_rev = $cvs_file->get_revision($sticky_info)

=over 4

=item return type: VCS::LibCVS::FileRevision

=item argument 1 type: VCS::LibCVS::Sticky

=back

Returns the revision of the file specified by the sticky info.

It doesn't handle the BASE tag.  The object model means it doesn't really
belong here, but in the LocalFile object.  I hope this isn't a problem.

=cut

sub get_revision {
  my $self = shift;
  my $sticky = shift;

  my $rev_number;

  # Each type of sticky data requires different behaviour
  if (ref($sticky) eq "VCS::LibCVS::StickyTag") {
    $rev_number = $self->_get_all_tags()->{$sticky->get_tag}->[1];
    return VCS::LibCVS::FileRevision->new($self, $rev_number);
  }
}

###############################################################################
# Private routines
###############################################################################

# get the tag info from private variables
# use this function instead of direct access to make it easier to add caching
sub _get_all_tags {
  my $self = shift;

  $self->_load_tags();
  return $self->{Tags};
}

# loads the tag info into the private variable Tags
sub _load_tags {
  my $self = shift;

  my $loginfo = $self->_get_loginfo_from_server({NoLog => 1});

  # The tag info is returned in this format:
  #
  # symbolic names:
  #       REGULAR_TAG: 1.2.2.1
  #       foo_branch: 1.2.0.2
  #
  # So it is processed by traversing the responses until we hit the string
  # "symbolic names:", after which we read them as tags.

  # In addition, the head revision is found elsewhere in a line of this format:
  # head: 1.2
  # It is used to put the HEAD tag in.

  my %tags;
  my $in_tags = 0;  # true after the "symbolic names:" message
  foreach my $line (@$loginfo) {
    if ($in_tags) {
      # check if the line specifies a tag
      # if it doesn't, then there are no more
      if ($line !~ /^\s+(.*): ([0-9.]*)$/) {
        last;
      } else {
        my ($tag_string, $rev_string) = ($1, $2);
        my $rev = VCS::LibCVS::Datum::RevisionNumber->new($rev_string);
        my $tagspec = VCS::LibCVS::Datum::TagSpec->
          new(($rev->is_branch() ? "T" : "N") . $tag_string);
        $tags{$tag_string} = [ $tagspec, $rev ];
      }
    } elsif ($line eq "symbolic names:") {
      $in_tags = 1;
    } elsif ($line =~ /head: ([0-9.]*)/) {
      my $rev = VCS::LibCVS::Datum::RevisionNumber->new($1);
      my $tagspec = VCS::LibCVS::Datum::TagSpec->new("NHEAD");
      $tags{"HEAD"} = [ $tagspec, $rev ];
    }
  }
  $self->{Tags} = \%tags;
}

# get the log messages from private variables
# use this function instead of direct access to make it easier to add caching
sub _get_log_messages {
  my $self = shift;

  $self->_load_log_messages();
  return $self->{Logs};
}

# loads the log messages into the private variable Logs
sub _load_log_messages {
  my $self = shift;

  my $loginfo = $self->_get_loginfo_from_server({NoTag => 1});

  # The log messages are returned in this format:
  #
  # description:
  # ----------------------------
  # revision 1.2
  # date: 2002/11/13 02:29:46;  author: dissent;  state: Exp;  lines: +1 -0
  # branches:  1.2.2;
  # logmessage
  # ----------------------------
  # revision 1.1
  # date: 2002/11/13 02:29:33;  author: dissent;  state: Exp;
  # *** empty log message ***
  # ----------------------------
  # revision 1.2.2.1
  # date: 2003/01/11 16:39:04;  author: dissent;  state: Exp;  lines: +1 -0
  # mm
  #
  # So it is processed by traversing the responses until we hit the string
  # "description:", after which log messages are split by ------ lines

  my %logs;
  # eat up everything up to and including the "description:" line
  while ( @$loginfo ) {
    last if (shift @$loginfo) eq "description:";
  }
  # the last line will be a bunch of ==, remove it now:
  my $last = pop @$loginfo;
  confess "Bad final log line: $last" unless $last =~ /={77}/;
  my $log_entry_sep = qr/-{28}/;
  while (@$loginfo) {
    my $f_l = shift @$loginfo;
    confess "Bad log entry separator: $f_l" unless $f_l =~ $log_entry_sep;
    my @log_mess_array;
    while (@$loginfo && ( $loginfo->[0] !~ $log_entry_sep )) {
      push (@log_mess_array, (shift @$loginfo));
    }
    my $log_mess = VCS::LibCVS::Datum::LogMessage->new(\@log_mess_array);
    $logs{$log_mess->get_revision()->as_string()} = $log_mess;
  }
  $self->{Logs} = \%logs;
}

# get various bits of the log info.
# may pass boolean options to select which bits to return:
# $file->_get_loginfo_from_server({ NoTags => 1, NoLog => 0 })
# it returns the loginfo as a ref to an array of lines
sub _get_loginfo_from_server {
  my $self = shift;
  my $options = shift || {};

  # To turn off retrieving log info, ask only for revisions that precede 1.1
  my $args = [ $options->{NoLog} ? "-r::1.1" : (),
               $options->{NoTags} ? "-N" : () ];

  my $command = VCS::LibCVS::Command->new({}, "log", $args, [$self]);
  $command->issue($self->{Repository});

  # Return the responses as a list of lines
  return [ $command->get_messages() ];
}

# Directory names for reporting to the server.
# Routine called in Command.pm, see there for more details.
sub _get_repo_dirs {
  my $self = shift;
  # Use the repository dir as the working directory required by the protocol
  my $l_dir = $self->get_name({no_base => 1});
  my $r_dir = $self->get_name({abs => 1, no_base => 1});
  return [ $l_dir, $r_dir ];
}

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
