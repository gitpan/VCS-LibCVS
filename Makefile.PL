#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile( ABSTRACT_FROM => "VCS/LibCVS.pm",
               AUTHOR => 'Alexander Taler <dissent@cpan.org>',
               NAME => "VCS::LibCVS",
               VERSION_FROM => "VCS/LibCVS.pm",
               depend => { Makefile => '$(VERSION_FROM)' },
               dist => { DIST_DEFAULT => 'MANIFEST permissions tardist' },
             );

sub MY::postamble {
  '
.FORCE:

MANIFEST: .FORCE
	find VCS -name \'*.pm\' -print > MANIFEST
	find examples -regex \'^.*lcvs-.*[^~]$$\' -print >> MANIFEST
	find . -name \'Makefile.PL\' -printf \'%P\n\' >> MANIFEST
	ls -1 COPYING MANIFEST README >> MANIFEST

# I don\'t have access to the repository to fix the permissions on these files
executables = Makefile.PL examples/Makefile.PL VCS/Makefile.PL \
              examples/lcvs-example examples/lcvs-st examples/lcvs-version \
              examples/t/lcvs-st.t examples/t/lcvs-st.t-setup.sh

permissions: .FORCE
	chmod +x $(executables)

';
}
