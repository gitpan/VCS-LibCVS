#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::RepositoryDirectory;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::RepositoryDirectory - A Directory in the repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a directory in the CVS repository.

=head1 SUPERCLASS

VCS::LibCVS::RepositoryFileOrDirectory

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS/RepositoryDirectory.pm,v 1.3 2003/06/27 20:52:32 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::RepositoryFileOrDirectory");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

###############################################################################
# Class routines
###############################################################################

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_files()>

@r_files = $r_dir->get_files()

=over 4

=item return type: list of VCS::LibCVS::RepositoryFile

=back

=cut

sub get_files {
  confess "Not Implemented";
}

=head2 B<get_directories()>

@r_files = $r_dir->get_directories()

=over 4

=item return type: list of VCS::LibCVS::RepositoryDirectory

=back

=cut

sub get_directories {
  confess "Not Implemented";
}

###############################################################################
# Private routines
###############################################################################

# Directory names for reporting to the server.
# Routine called in Command.pm, see there for more details.
sub _get_repo_dirs {
  my $self = shift;
  # Use the repository dir as the working directory required by the protocol
  return [ $self->get_name({}), $self->get_name({abs => 1}) ];
}


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
