#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::Connection::Local;

use strict;
use Carp;
use FileHandle;
use IPC::Open2;

# Use a subclass of FileHandle which logs traffic.
# Makes debugging a bit easier
use VCS::LibCVS::Client::LoggingFileHandle;

=head1 NAME

VCS::LibCVS::Client::Connection::Local - a connection to a local cvs server

=head1 SYNOPSIS

  my $conn = VCS::LibCVS::Client::Connection::Local->new();
  my $client = VCS::LibCVS::Client->new($conn, "/home/cvs");

=head1 DESCRIPTION

A connection to an invocation of "cvs server" on the localhost.  See
VCS::LibCVS::Client::Connection for an explanation of the API.

No authentication is required to establish this connection.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Connection

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Client/Connection/Local.pm,v 1.7 2003/06/27 20:52:33 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Client::Connection");

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$local_connection = Client::Connection::Local->new()

=over 4

=item return type: Client::Connection::Local

=back

Construct a new local CVS connection, just invocation of "cvs server".

=cut

sub new {
  my $class = shift;
  return bless {}, $class;
}

###############################################################################
# Instance routines
###############################################################################

# connect launches a process and connects its filehandles to it, using
# IPC::Open2

sub connect {
  my $self = shift;

  return if $self->connected();

  $self->{FromServer} = VCS::LibCVS::Client::LoggingFileHandle->new();
  $self->{ToServer} = VCS::LibCVS::Client::LoggingFileHandle->new();

  IPC::Open2::open2($self->{FromServer}, $self->{ToServer}, "cvs server");
  $self->SUPER::connect();
}

# disconnecting from CVS is merely a matter of closing the file handles.

sub disconnect {
  my $self = shift;

  return if ! $self->connected();

  $self->SUPER::disconnect();
  $self->{ToServer}->close();
  $self->{FromServer}->close();
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Connection

=cut

1;
