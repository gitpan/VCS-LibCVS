#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Client - an implementation of the CVS client protocol

=head1 SYNOPSIS

 use VCS::LibCVS::Client;
 use VCS::LibCVS::Datum;

 my $conn = VCS::LibCVS::Client::Connection::Local->new();
 my $client = VCS::LibCVS::Client->new($conn, "/cvs");
 $client->connect();
 my $request
   = VCS::LibCVS::Client::Request::Directory->new(["dir","/cvs/dir"]));
 my @responses = $client->submit_request($request);

=head1 DESCRIPTION

VCS::LibCVS provides native Perl access to CVS.  This is the CVS client
protocol component of VCS::LibCVS.  Do not use this directly, use
VCS::LibCVS instead.  However, if you really insist, this
implementation does work stand-alone.

This documentation assumes you are already familiar with the cvsclient
protocol which is documented in the cvsclient info node.

This module uses exceptions to report errors, except where otherwise noted.

This implementation is a very thin layer over the CVS client protocol, although
in some places it does a little more, including the following:

=over 4

=item Initial negotiation

When you call connect on the Client, it sends some required requests to the
server, and receives some responses from the server.  See the documentation of
that routine for more details.

=item Argumentx

There is no Argumentx request, instead Client::Request::Argument handles
strings with embedded newlines and issues the Argumentx request itself.

=back

Throughout these docs, all classnames are relative to VCS::LibCVS::,
unless they start with ::.

=head1 CLASSES

This is a summary of the classes in this implementation.  For more details on
each of the classes, please see the corresponding docs.

=head2 Client

This is the main class of the implementation, its instances represent the
client end of the CVS client protocol.  In order to construct a Client, an
instance of Client::Connection must be provided.  After construction, a
connect() must be called to connect the Client to the server.  After a
connection has been established, Client::Request's may be submitted to it, and
Client::Response's will be received from it.

=head2 Client::Connection

Instances of this class represent a connection to a particular CVS server.
There are several possible types of connection, each with its own subclass,
such as Client::Connection::Local.  A Client::Connection can be ignored once it
has been used to construct a Client and it should not be used to create more
than one Client.  Note that a CVS server, and thus a Client::Connection, can
provide access to more than one CVS repository, for example, there could be
repositories at /home/cvs and /home/user1/repository.

=head2 Client::Request

Instances of this class represent protocol requests which are to be sent to the
server.  It has subclasses, such as Client::Request::Directory, for each type
of protocol request.  Each subclass takes specific types of arguments, which
are provided in the constructor, either with Datum instances of the appropriate
type, or with data that could be used to construct those Datum instances.  The
routine Client->submit_request() is used to send Client::Request's to the
server.

=head2 Client::Response

Instances of this class represent protocol responses which have been received
from the server.  It has subclasses, such as Client::Response::Merged for each
type of protocol response.  The arguments of the response are accessed as
instances of subclasses of Datum.  Client::Response's are returned by the
Client->submit_request() routine.

=head1 VCS::LibCVS::Client

The rest of this documentation is for the VCS::LibCVS::Client class itself.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Client.pm,v 1.23 2003/06/27 20:52:32 dissent Exp $ ';

# The default list of valid responses that the client will report
use constant DEFAULT_VALID_RESPONSES =>
   ("ok", "error", "Valid-requests", "E", "M", "Set-sticky", "Clear-sticky",
    "Mode", "Mod-time",
    "Checked-in", "New-entry", "Updated", "Created", "Update-existing",
    "Merged", "Removed", "Remove-entry",
   );

# Turn on and off what to debug
use vars ('$DebugLevel');
$DebugLevel = 0;  # Bitmask indicating what debug info to output
use constant DEBUG_PROTOCOL => 1;  # Print all the protocol data

# The rest of the VCS::LibCVS::Client classes.
#
# They use the constants defined above.

use VCS::LibCVS::Client::Connection;
use VCS::LibCVS::Client::Connection::Local;
use VCS::LibCVS::Client::Request;
use VCS::LibCVS::Client::Request::Requests;
use VCS::LibCVS::Client::Request::ArgumentUsingRequests;
use VCS::LibCVS::Client::Request::Argument;
use VCS::LibCVS::Client::Response;
use VCS::LibCVS::Client::Response::Responses;
use VCS::LibCVS::Client::Response::FileUpdatingResponses;
use VCS::LibCVS::Client::Response::FileUpdateModifyingResponses;

###############################################################################
# Private variables
###############################################################################

# Client is a hash, and uses the following private entries:
#
# Connected  => boolean.  True if connected.
# Connection => object of type Connection
#               set in the constructor
# Root       => string indicating Root directory on server
#               set in the constructor
# ValidResponses => hash ref.  Keys for each library supported response, values
#                   of 0 or 1 indicating if the response is valid, as
#                   customized by the user of the library.
# ValidRequests  => hash ref.  Keys for each server supported request, values
#                   of 0 or 1 indicating if the request is valid, as
#                   reported by the server.

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$client = Client->new($conn, $root_dir)

=over 4

=item return type: Client

=item argument 1 type: Client::Connection

A connection to the server which the client should use.  It need not be
connected already.

=item argument 2 type: string scalar

The root directory of the CVS repository which the client should use.

=back

=cut

sub new {
  my ($class, $conn, $root) = @_;
  my $that = bless {}, $class;

  confess "First arg must be a VCS::LibCVS::Client::Connection"
    unless (defined ($conn) && $conn->isa("VCS::LibCVS::Client::Connection"));

  $that->{Root} = $root;
  $that->{Connection} = $conn;
  $that->{Connected} = 0;

  # Initialize the default valid responses
  $that->{ValidResponses} = {};
  foreach my $response_name (@VCS::LibCVS::Client::Response::Valid_responses) {
    $that->{ValidResponses}->{$response_name} = 0;
  }
  foreach my $response_name (VCS::LibCVS::Client::DEFAULT_VALID_RESPONSES) {
    $that->{ValidResponses}->{$response_name} = 1;
  }

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<connect()>

$client->connect()

=over 4

=item return type: undef

=back

Causes the Client to initiate a connection with the server, using the
parameters provided when it was constructed.

First it establishes a connection to the server using its Connection object.
Then it performs an initial negotiation with the server, by issuing the
following requests:

=over 4

=item valid-requests

Asks the server for a list of requests it supports.  To find out what these
are, use the valid_requests() routine.

=item Valid-responses

Tells the server what responses this client supports.  To configure these use
the valid_responses() routine.

=item Root

Tells the server which directory contains the repository we wish to use.

=item UseUnchanged

Tells the server which version of the protocol to use.

=back

=cut

sub connect {
  my $self = shift;

  confess "Client already connected to $self->{Root}" if $self->{Connected};

  $self->{Connection}->connect();

  # Get the server's valid requests
  $self->_submit_valid_requests();

  # Tell the server what the valid responses are
  my $vrsp_str = "";
  while (my ($rsp_name, $on) = each %{$self->valid_responses}) {
    $vrsp_str .= $rsp_name . " " if $on;
  }
  my $vrsp = VCS::LibCVS::Client::Request::Valid_responses->new([$vrsp_str]);
  $self->submit_request($vrsp);

  # Send the server my Root
  my $root_request = VCS::LibCVS::Client::Request::Root->new([ $self->{Root} ]);
  $self->submit_request($root_request);

  # Tell the server what version of the protocol to use via UsaUnchanged
  my $useu_request = VCS::LibCVS::Client::Request::UseUnchanged->new();
  $self->submit_request($useu_request);

  $self->{Connected} = 1;

  return;
}

=head2 B<disconnect()>

$client->disconnect()

=over 4

=item return type: undef

=back

Disconnects this client from the server.

=cut

sub disconnect {
  my $self = shift;
  $self->{Connection}->disconnect();
  $self->{Connected} = 0;
  return;
}


=head2 B<init_repository()>

$client->init_repository()

=over 4

=item return type: undef

=back

Creates a new repository at the Root specified when the client was constructed.
The client must be disconnected when you call this routine.

=cut

sub init_repository {
  my $self = shift;

  if ($self->{Connection}->connected()) {
    confess "Must be disconnected to init a repository";
  }

  $self->{Connection}->connect();

  $self->_submit_valid_requests();

  my $init_request = VCS::LibCVS::Client::Request::init->new([ $self->{Root} ]);
  my @responses = $self->submit_request($init_request);

  $self->{Connection}->disconnect();

  # Check that the init was a success
  if (!(pop(@responses)->isa("VCS::LibCVS::Client::Response::ok"))) {
    my $errors = ""; map { $errors .= $_->get_errors(); } @responses;
    confess "Init failed: $errors";
  }
}

=head2 B<submit_request()>

@responses = $client->submit_request($request)

=over 4

=item return type: a list of Client::Response objects

Returns responses in the order they were generated by the server.  Some
requests do not generate a response, in which case this will be an empty list.
You can ask a Client::Request if it expects a response.

=item argument 1 type: Client::Request

An instance of a subclass of Client::Request.  This must be a request type
which is supported by the server.

=back

Sends the request to the server, and returns any responses from the server.  No
processing is done on the responses.  The last request in the list will be an
ok or error response, so use the following to check if the request succeeded:

C<pop(@responses)-E<gt>isa("VCS::LibCVS::Client::Response::ok")>

=cut

sub submit_request {
  my ($self, $request) = @_;

  confess "This request isn't supported by the server: " . $request->name()
    unless $self->{ValidRequests}->{$request->name()};

  $request->protocol_print($self->{Connection}->get_fh_to_server());

  return () if (!$request->response_expected());

  my $in = $self->{Connection}->get_fh_from_server();
  return VCS::LibCVS::Client::Response->read_from_fh($in);
}

=head2 B<valid_responses()>

$valid_responses = $client->valid_responses()

=over 4

=item return type: a hash ref containing the valid responses

=back

Returns a hash ref of supported responses, as it will be reported to the
server.  What is sent to the server may be customized before opening the
connection.

The keys of the hash are the names of the responses supported by the library,
and are not to be modified.  The values are booleans and indicate whether or
not the client wants to report that response as valid, and may be modified.
The initial state of the hash has a pre-defined list of responses turned on,
those listed in the constant VCS::LibCVS::Client::DEFAULT_VALID_RESPONSES.

=cut

sub valid_responses {
  my $self = shift;
  return $self->{ValidResponses};
}

=head2 B<valid_requests()>

$valid_requests = $client->valid_requests()

=over 4

=item return type: a hash ref containing the names of the valid requests

=back

Returns a hash ref of requests supported by the server.  This must be called
when the Client is connected to the server.

The keys of the hash are the names of all the requests supported by either the
server or the client.  The values are booleans indicating whether the
particular request is supported by the server.

=cut

sub valid_requests {
  my $self = shift;
  return $self->{ValidRequests};
}

###############################################################################
# Private routines
###############################################################################

# this routine submits the valid_requests request, and stores the results.
sub _submit_valid_requests {
  my $self = shift;

  # initialize the ValidRequests variable with all the requests available in
  # this implementation.  We can't assume the server supports them
  $self->{ValidRequests} = {};
  foreach my $req_name (@VCS::LibCVS::Client::Request::Valid_requests) {
    $self->{ValidRequests}->{$req_name} = 0;
  }

  # bootstrap the request validity checking mechanism used in submit_request
  $self->{ValidRequests}->{'valid-requests'} = 1;

  my $vrqs_request = VCS::LibCVS::Client::Request::valid_requests->new();
  my @responses = $self->submit_request($vrqs_request);

  my $last_response = pop(@responses);
  confess "valid_requests failed " . $last_response->data->[0]->as_string
    unless (   $last_response->isa("VCS::LibCVS::Client::Response::ok")
            && (@responses == 1));

  # Populate the ValidRequests hash with the results
  foreach my $req_name (split /\s/, $responses[0]->data->[0]->as_string) {
    $self->{ValidRequests}->{$req_name} = 1;
  }

  return;
}

1;
