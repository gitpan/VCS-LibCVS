#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Repository;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Repository - A CVS Repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a CVS Repository.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Repository.pm,v 1.12 2003/06/27 20:52:32 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

# Cache Repository objects.  Any attempt to create a new repository object with
# the same Root will return one from the cache.
use vars ('%Repository_Cache');

###############################################################################
# Private variables
###############################################################################

# $self->{Root}     object of type VCS::LibCVS::Datum::Root
# $self->{Client}   already connected VCS::LibCVS::Client

# $self->{RepositoryFileOrDirectoryCache} hashref containing
#                                         RepositoryFileOrDirectory instances
#                                         in this repo, keys are filenames
#                                         relative to the root

##########
# $self->{FileRevisionContentsCache} hashref containing file revision contents
#
# keys are filenames (relative to the root) and revisions, like so:
# "CVSROOT/modules:1.2"
#
# This cache is populated by objects of type FileRevision.  This cache is
# necessary because of the way CVS works; it won't return the contents of the
# same revision twice in a row over a single client connection.
#
# It can grow large if FileRevision is used often across a single connection.
# For this reason it makes sense to clean it up as soon as possible once the
# connection comes down.  That's why the cache is here and not in the
# FileContents class itself.  Furthermore, if another class wanted direct
# access to the contents of a revision, it would need access to this Cache
# also.
##########

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$repo = VCS::LibCVS::Repository->new($root)

=over 4

=item return type: VCS::LibCVS::Repository

=item argument 1 type: . . .

The root of the repository, like this: :pserver:user@cvs.cvshome.org:/cvs

=over 2

=item E<32>E<32>option 1: scalar string

=item E<32>E<32>option 2: VCS::LibCVS::Datum::Root

=back

=back

Creates a new Repository object with the specified root.

There is no check that the specified repository actually exists or is
accessible.

=cut

sub new {
  my $class = shift;
  my $root = shift;
  my $root_string;

  if (!ref($root)) {
    $root_string = $root;
    $root = VCS::LibCVS::Datum::Root->new($root);
  } else {
    $root_string = $root->as_string();
  }

  if ($VCS::LibCVS::Cache_Repository && $Repository_Cache{$root_string}) {
    return ($Repository_Cache{$root_string})
  }

  my $that = bless {}, $class;
  $that->{Root} = $root;
  $that->{FileRevisionContentsCache} = {};
  $that->{RepositoryFileOrDirectoryCache} = {};

  $Repository_Cache{$root_string} = $that if $VCS::LibCVS::Cache_Repository;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_root()>

$root = $repo->get_root()

=over 4

=item return type: VCS::LibCVS::Datum::Root

=back

Returns the root of this repository

=cut

sub get_root {
  my $self = shift;
  return $self->{Root};
}

=head2 B<get_version()>

$CVS_version = $repo->get_version()

=over 4

=item return type: scalar string

=back

Returns the version of CVS running at this repository

=cut

sub get_version {
  my $self = shift;

  my $client = $self->_new_client();
  $client->connect();

  # If the version request is not supported, then it's pre 1.11
  return "pre 1.11" unless ($client->valid_requests()->{version});

  # Call the version request and return its result
  my $request = VCS::LibCVS::Client::Request::version->new();
  my @responses = $client->submit_request($request);

  # Throw an exception in case of error
  if (($responses[-1]->isa("VCS::LibCVS::Client::Response::error"))) {
    my $errors;
    foreach my $resp (@responses) { $errors .= ($resp->get_errors() || ""); };
    confess "Request failed: \"$errors\"";
  }

  # The first response should be of type M, with it's value the version
  return $responses[0]->get_message();
}

###############################################################################
# Private routines
###############################################################################

# VCS::LibCVS::Client
#
# Returns a client connected to this repository
# Used in Command.pm

sub _get_client {
  my $self = shift;

  return $self->{Client} if $self->{Client};

  my $client = $self->_new_client();
  $client->connect();

  $self->{Client} = $client;
  return $client;
}

# create a new client, not connected to the repo.

sub _new_client {
  my $self = shift;

  my $conn;
  if ($self->{Root}->{Protocol} =~ /^(local|fork)$/) {
    $conn = VCS::LibCVS::Client::Connection::Local->new();
  } else {
    confess "Unsupported protocol: $self->{Root}->{Protocol}";
  }
  my $client = VCS::LibCVS::Client->new($conn, $self->{Root}->{RootDir});
  # Turn off two possible responses.  This will put all file transmissions
  # through the Updated responses, which is fine since this client is smarter
  # than the regular cvs client.
  $client->valid_responses()->{'Update-existing'} = 0;
  $client->valid_responses()->{'Created'} = 0;

  return $client;
}

# Clean up the Repository_Cache
sub END {
  foreach my $key (keys (%Repository_Cache)) {
    delete ($Repository_Cache{$key});
  }
}

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
