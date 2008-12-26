#use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $ENDIAN =  unpack('S', pack('C2', 0, 1)) == 1 ? 'BIG' : 'LITTLE';

my $DEFINE = "-D${ENDIAN}_END";
if ($Config{osname} eq 'MSWin32'){
            $DEFINE.=" -DMSWin32";
            system "perl", qw( -i bak -p -e), "s/^\s*inline\s*//", "AMF.xs";
}
our %REQUIRE = ( 
	PREREQ_PM => {}, # e.g., Module::Name => 1.1
	MIN_PERL_VERSION => 5.008000,
	);


# Perl 5.6.2 or less not supported
if  ($]< $REQUIRE{MIN_PERL_VERSION}) {
	print "Perl $] not supported by this module\n";
    exit(0) ;
}
if ($ExtUtils::MakeMaker::VERSION < 6.48) {
	my $version = delete $REQUIRE{'MIN_PERL_VERSION'};
#	$REQUIRE{PREREQ_PM}{perl}= $version;
};
#print $ExtUtils::MakeMaker::VERSION, "\n";

#print "This is ${ENDIAN}_ENDIAN machine\n";

our %MyModule= (
    NAME              => 'Storable::AMF',
    VERSION_FROM      => 'lib/Storable/AMF0.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Storable/AMF.pm', # retrieve abstract from module
       AUTHOR         => 'Grishaev Anatoliy  <grian@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => $DEFINE, # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
	OPTIMIZE => "-O3 -pipe -fomit-frame-pointer ",
	($ExtUtils::MakeMaker::VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
	%REQUIRE, 
);
use Config;

delete $MyModule{OPTIMIZE} if (
      $Config{osname}=~/solaris/
    or $Config{cc} eq 'cl');

WriteMakefile(%MyModule);
# -march=opteron -O3 -pipe -fomit-frame-pointer 
