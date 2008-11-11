use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Storable::AMF',
    VERSION_FROM      => 'lib/Storable/AMF.pm', # finds $VERSION
    PREREQ_PM         => {
	'File::Spec' =>0,
		Carp => 0,
		'Data::Dumper'=>0,
		Fcntl=>0, 
		Test::More=>0,
		ExtUtils::testlib=>0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Storable/AMF.pm', # retrieve abstract from module
       AUTHOR         => 'Grishaev Anatoliy  <gtoly@combats.ru>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
	OPTIMIZE => "-O3 -pipe -fomit-frame-pointer ",
);
# -march=opteron -O3 -pipe -fomit-frame-pointer 
