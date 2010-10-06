#use 5.008000;
use ExtUtils::MakeMaker;

my $a = eval {
    require Module::Build::Compat;
    require ExtUtils::CBuilder;
    require ExtUtils::ParseXS;
};
#~ if ( not $@ and ( $Config{osname} ne 'MSWin32' ) ) {
#~     Module::Build::Compat->run_build_pl( args => \@ARGV );
#~     Module::Build::Compat->write_makefile();
#~     exit();
#~ }

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
exit if ( @ARGV && $ARGV[0] eq '--stop' );

use File::Copy;
use Cwd;
copy( 'lib/Storable/AMF.xs',   cwd() );
copy( 'lib/Storable/ppport.h', cwd() );

our %REQUIRE = (
    PREREQ_PM => { 
        'Module::Build::Compat' => 0.02, 
        'Module::Build' => 0.2,
        }
    ,    # e.g., Module::Name => 1.1
    #DISTVNAME => './Storable-AMF-0.65',
    MIN_PERL_VERSION => 5.008000,
);

# Perl 5.6.2 or less not supported
if ( $] < $REQUIRE{MIN_PERL_VERSION} ) {
    print "Perl $] not supported by this module\n";
    exit(0);
}
if ( $ExtUtils::MakeMaker::VERSION < 6.48 ) {
    my $version = delete $REQUIRE{'MIN_PERL_VERSION'};

    #	$REQUIRE{PREREQ_PM}{perl}= $version;
}

#print $ExtUtils::MakeMaker::VERSION, "\n";

our %MyModule = (
    NAME         => 'Storable::AMF',
    VERSION_FROM => 'lib/Storable/AMF0.pm',    # finds $VERSION
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT => 'serializing/deserializing AMF0/AMF3 data',
            AUTHOR => 'Grishaev Anatoliy  <grian@cpan.org>'
          )
        : ()
    ),
    INC    => '-I.',    # e.g., '-I. -I/usr/include/other'
                        # Un-comment this if you add C files to link with later:
         # OBJECT            => '$(O_FILES)', # link all the C files too
    OPTIMIZE => "-O3 -pipe -fomit-frame-pointer ",
    ( $ExtUtils::MakeMaker::VERSION >= 6.31 ? ( LICENSE => 'perl' ) : () ),
    %REQUIRE,
);
use Config;

delete $MyModule{OPTIMIZE}
  if ( $Config{osname} =~ /solaris/
    or $Config{cc} eq 'cl' );
if ( $Config{cc} eq 'gcc' ) {
    $MyModule{CCFLAGS} = '-Wunused';    # --warn-no-unused-parameter';
      #$MyModule{CCFLAGS} = '-Wunused-variable -Wunused-label -Wunused-function -Wuninitialized -Wunused-value'

    #    -Wunreachable-code -Wunsafe-loop-optimizations';
}

WriteMakefile(%MyModule);

# -march=opteron -O3 -pipe -fomit-frame-pointer
