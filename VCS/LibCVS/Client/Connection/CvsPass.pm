#
# Copyright 2004 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::Connection::CvsPass;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Client::Connection::CvsPass - A ~/.cvspass file.

=head1 SYNOPSIS

  my $cvspass = VCS::LibCVS::Client::Connection::CvsPass->new();
  my $password = $cvspass->get_password($root);

=head1 DESCRIPTION

A ~/.cvspass file.  This file contains the trivially encoded passwords used by
the CVS pserver authentication system.  This interface provides access to the
passwords.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/Client/Connection/CvsPass.pm,v 1.2 2004/04/28 02:32:00 dissent Exp $ ';

###############################################################################
# Private variables
###############################################################################

# CvsPass is a hash, and uses the following private entries.
#
# $self->{Passwords} is a hash ref, whose keys are Root specifications in the
# format of the password file (eg :pserver:dissent@fire.0--0.org:2401/cvs), and
# whose values are the encoded password for that root.

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$cvspass = VCS::LibCVS::Client::Connection::CvsPass->new();

=over 4

=item return type: VCS::LibCVS::Client::CvsPass

=back

Return a new CvsPass object, for the current user, found in their home
directory.

=cut

sub new {
  my $class = shift;

  my $that = bless {}, $class;

  $that->{Passwords} = {};

  if ( -e get_passfilename()) {
    my $pass_file = IO::File->new(get_passfilename());
    confess "Couldn't read: ". get_passfilename() unless defined $pass_file;
    foreach my $pass_line ($pass_file->getlines()) {
      if ($pass_line =~ m#^/1 (:pserver:.*) (.*)$#) {
        $that->{Passwords}->{$1} = $2;
      }
    }
    $pass_file->close();
  }

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_password()>

$password = $cvspass$->get_password($root)

=over 4

=item return type: scalar string

=item argument 1 type: VCS::LibCVS::Datum::Root

=back

Retrieve the password for the indicated repository.

=cut

sub get_password {
  my $self = shift;
  my $root = shift;

  my $rootString = (":pserver"
                    . ":" . $root->{UserName}
                    . "@" . $root->{HostName}
                    . ":" . ($root->{Port} || "2401")
                    . $root->{RootDir});
  return $self->{Passwords}->{$rootString};
}

=head2 B<store_password()>

$cvspass$->store_password($root, $password)

=over 4

=item return type: undef

=item argument 1 type: VCS::LibCVS::Datum::Root

=item argument 2 type: scalar string

The scrambled password.

=back

Store a password for the repository.  The password must be scrambled using the
pserver scrambling technique.  See
VCS::LibCVS::Client::Connection::Pserver::pserver_scramble() for details.

=cut

sub store_password {
  my $self = shift;
  my ($root, $password) = @_;

  my $rootString = (":pserver"
                    . ":" . $root->{UserName}
                    . "@" . $root->{HostName}
                    . ":" . ($root->{Port} || "2401")
                    . $root->{RootDir});

  $self->{Passwords}->{$rootString} = $password;
  $self->append($rootString, $password);
  return;
}


###############################################################################
# Private routines
###############################################################################

# Append a password to .cvspass

sub append {
  my $self = shift;
  my ($root, $password) = @_;

  my $pass_file = IO::File->new(get_passfilename(), "a");

  confess "Couldn't append to: ". get_passfilename() unless defined $pass_file;

  $pass_file->print("/1 $root $password\n");
  $pass_file->close();

  return;
}

# Get the name of the cvs pass file:

sub get_passfilename {
  my $pass_filename = File::Spec->catpath('', $ENV{HOME}, ".cvspass");
  return $pass_filename;
}

=pod

=head1 SEE ALSO

  VCS::LibCVS::Client::Connection::Pserver

=cut

1;
