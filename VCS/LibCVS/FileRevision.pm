#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::FileRevision;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::FileRevision - A specific revision of a file managed by CVS.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a single revision of a file managed by CVS.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/FileRevision.pm,v 1.12 2003/06/27 20:52:32 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{File}             VCS::LibCVS::RepositoryFile of this revision
# $self->{RevisionNumber}   VCS::LibCVS::Datum::RevisionNumber
# $self->{LogMessage}       VCS::LibCVS::Datum::LogMessage (fetched on demand)

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$file_rev = VCS::LibCVS::FileRevision->new($file, $revision)

=over 4

=item return type: VCS::LibCVS::FileRevision

=item argument 1 type: VCS::LibCVS::RepositoryFile

=item argument 2 type: VCS::LibCVS::Datum::RevisionNumber

=back

=cut

sub new {
  my $class = shift;
  my ($file, $revision) = @_;
  my $that = bless {}, $class;

  $that->{File} = $file;
  $that->{RevisionNumber} = $revision;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_revision_number()>

$file = $file_rev->get_revision_number()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

=cut

sub get_revision_number {
  return shift->{RevisionNumber};
}

=head2 B<get_file()>

$file = $file_rev->get_file()

=over 4

=item return type: VCS::LibCVS::RepositoryFile

=back

=cut

sub get_file {
  return shift->{File};
}

=head2 B<get_log_message()>

$message = $file_rev->get_log_message()

=over 4

=item return type: scalar string

=back

Returns the text of the log message for the commit that resulted in this
revision.

=cut

sub get_log_message {
  return shift->_get_log_message()->get_text();
}

=head2 B<get_committer()>

$committer = $file_rev->get_committer()

=over 4

=item return type: scalar string

=back

Returns the logname of whoever committed this particular revision.

=cut

sub get_committer {
  return shift->_get_log_message()->{Author};
}

=head2 B<get_contents()>

$data = $file_rev->get_contents()

=over 4

=item return type: VCS::LibCVS::Datum::FileContents

=back

Returns the contents of the particular revision.

=cut

# This function could use stdout mode ("-p") to avoid getting all the entries
# and stuff, but it would then receive the file as a series of "M" messages.
# This format of output worries me.

sub get_contents {
  my $self = shift;

  # Check if the file contents have been cached
  my ($cache, $c_key);
  if ($VCS::LibCVS::Cache_FileRevision_Contents_by_Repository) {
    $cache = $self->get_file->get_repository->{FileRevisionContentsCache};
    $c_key = $self->get_file->get_name.":".$self->{RevisionNumber}->as_string;
    return ($cache->{$c_key}) if ($cache->{$c_key});
  }

  # Specify which revision to get the contents of
  my $arg = [ "-r" . $self->{RevisionNumber}->as_string() ];

  # Generate and issue the command
  my $command = VCS::LibCVS::Command->new({},"update",$arg, [$self->get_file]);
  $command->issue($self->get_file()->get_repository());

  # The file is returned in an Updated response, as a FileContents Datum
  my @resps = $command->get_responses("VCS::LibCVS::Client::Response::Updated");
  confess "Not 1 Updated for " . $self->get_file->get_name unless (@resps == 1);

  # Cache and return the results
  if ($VCS::LibCVS::Cache_FileRevision_Contents_by_Repository) {
    ($cache->{$c_key}) = $resps[0]->data()->[3];
  }
  return $resps[0]->data()->[3];
}

###############################################################################
# Private routines
###############################################################################

# get the Datum::LogMessage object for this particular file revision the
# difference between this and get_log_message is the return type.  I don't
# think it's appropriate for the external API to return a Datum::LogMessage
# object.

sub _get_log_message {
  my $self = shift;
  if (!defined $self->{LogMessage}) {
    my $rev_num_str = $self->{RevisionNumber}->as_string();
    $self->{LogMessage} = $self->{File}->_get_log_messages()->{$rev_num_str};
  }
  return $self->{LogMessage};
}

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
