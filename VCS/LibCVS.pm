#
# Copyright 2003 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS;

use strict;

# Internals

use VCS::LibCVS::Client;
use VCS::LibCVS::Admin;
use VCS::LibCVS::IgnoreChecker;
use VCS::LibCVS::Command;

=head1 NAME

VCS::LibCVS - Access CVS working directories and repositories.

=head1 SYNOPSIS

Please see the example script, examples/lcvs-example.

  $working_dir = VCS::LibCVS::WorkingDirectory->new(File::Spec->curdir);

=head1 DESCRIPTION

LibCVS provides native Perl access to CVS.

These docs assume some familiarity with concepts of CVS.  For example, the term
"Working Directory" (or sandbox) refers to a collection of directories and
files which have been checked out of CVS.

The API is provided through a collection of classes.  They come in 3 groups,
Working Directory Classes, Repository Classes, and Other Classes.  A brief
description of each class is provided here, for more details see its perldoc.

For a language independent description of the API, please see the docs at
libcvs.cvshome.org.

=head2 Working Directory classes

These classes give you access to the stuff in a working directory, as governed
by the standard CVS working directory admin information (CVS/*).  They also
provide several ways to get at information the repository, or compare against
what's in the repository.

You will probably find the need to construct objects of these types explicitly.

=over 4

=cut

use VCS::LibCVS::WorkingFileOrDirectory;
use VCS::LibCVS::WorkingFile;
use VCS::LibCVS::WorkingDirectory;
use VCS::LibCVS::WorkingUnmanagedFile;

=item VCS::LibCVS::WorkingFileOrDirectory

A parent class for all the types of files and directories that you find in a
working directory.

=item VCS::LibCVS::WorkingFile

A file which is being managed by CVS.  It has either been checked out of the
repository, or given to CVS with "cvs add".

=item VCS::LibCVS::WorkingDirectory

A directory which is being managed by CVS.

=item VCS::LibCVS::WorkingUnmanagedFile

A file which upsets CVS.  It's in a CVS working directory, but it's not in the
repository, it has been "cvs add"ed, and it's not in any of the ignore lists.

=back

=head2 Repository classes

These classes give you access to the stuff in the repository.  They use the
remote protocol to get at the repository, so they don't require any local CVS
directory.  You will need a CVSROOT to find the repo though.

The only classes here that you should need to construct explicitly are those
named VCS::LibCVS::Repository*.

=over 4

=cut

use VCS::LibCVS::Repository;

=item VCS::LibCVS::Repository

The CVS repository.

=cut

use VCS::LibCVS::RepositoryFileOrDirectory;
use VCS::LibCVS::RepositoryFile;
use VCS::LibCVS::RepositoryDirectory;

=item VCS::LibCVS::RepositoryFileOrDirectory

Parent class for repository files and directories.

=item VCS::LibCVS::RepositoryFile

A file in the repository.  It's really a collection of revisions, and a bunch
of branch and tag information too.

=item VCS::LibCVS::RepositoryDirectory

A directory in the repository.  Really just a container for files, but it is
treated as having branches.

=cut

use VCS::LibCVS::DirectoryBranch;

=item VCS::LibCVS::DirectoryBranch

A branch of a directory.  This is really just a stepping stone to getting
specific branches of many files at once.

=cut

use VCS::LibCVS::FileBranch;
use VCS::LibCVS::FileRevision;
use VCS::LibCVS::FileSticky;

=item VCS::LibCVS::FileBranch

A specific branch of a file.  Or a collection of revisions from another
perspective.

=item VCS::LibCVS::FileRevision

A specific revision of a file.

=item VCS::LibCVS::FileSticky

A specific revision of a file, as specified by some sticky information.

=cut

use VCS::LibCVS::Sticky;
use VCS::LibCVS::StickyTag;

=item VCS::LibCVS::Sticky

A piece of sticky information, across the repository.  Really, a slice of the
repository.  This class ought to be renamed, and rethought.

=item VCS::LibCVS::StickyTag

A sticky tag, across the repository.  Really, a slice of the repository.  This
class ought to be renamed, and rethought.

=cut

use VCS::LibCVS::Datum;

=head2 Other classes

These classes are used by both the groups of classes above.

=item VCS::LibCVS::Datum and children

These classes reprsent various common bits of information in CVS, for example,
revision numbers.  You shouldn't need to construct these directly, they are
returned by various routines in the other objects.

=head1 WARNINGS

=head2 Absolute And Relative Filenames

Objects are created using filenames.  These may be relative or absolute, and
are stored as such, so be careful if you change the current directory.

=head2 Root vs. Repository

A repository is a place where managed files are stored.  A root is a string
which specifies a repository.

=cut

###############################################################################
# Constants
###############################################################################

use constant REVISION => '$Header: /cvs/libcvs/Perl/VCS/LibCVS.pm,v 1.15 2003/06/27 20:52:32 dissent Exp $ ';
use constant VERSION_TAG => '$Name: Release-Perl-1-00-00 $';

use vars ('$VERSION');
$VERSION = 1.0000_0;

###############################################################################
# Variables
###############################################################################

=head1 CONFIG VARIABLES

=head2 $Admin_Dir_Name    scalar string, default "CVS"

The name of the sandbox admin directory.

=cut

use vars ('$Admin_Dir_Name');
$Admin_Dir_Name = "CVS";

=head2 $Cache_Repository   boolean, default "1"

True means that VCS::LibCVS::Repository objects should be cached and reused.
If you construct a Repository object, and one already exists with the same
root, then the existing one will be reused.  Roots are compared as strings, so
different usernames, alias hostnames, and symlinks in repository directories
will defeat the cache.  This is of course risky for multi-thread environments.

=cut

use vars ('$Cache_Repository');
$Cache_Repository = 1;

=head2 $Cache_RepositoryFileOrDirectory   boolean, default "1"

True means that VCS::LibCVS::RepositoryFileOrDirectory objects should be cached
and reused.  If you construct a RepositoryFileOrDirectory object, and one
already exists with the same filename and repository, then the existing one
will be reused.  This is of course risky for multi-thread environments.

=cut

use vars ('$Cache_RepositoryFileOrDirectory');
$Cache_RepositoryFileOrDirectory = 1;

=head2 $Cache_FileRevision_Contents_by_Repository  boolean, default "1"

True means that results of fetching the contents of a file revision should be
cached for each Repository object.  This cache is necessary because of the way
CVS works; it won't return the contents of the same revision twice in a row
over a single client connection.  You shouldn't change this unless you really
know what you are doing.  It is used in the routine
VCS::LibCVS::FileRevision->get_contents().

=cut

use vars ('$Cache_FileRevision_Contents_by_Repository');
$Cache_FileRevision_Contents_by_Repository = 1;



=head1 SEE ALSO

=cut

1;
