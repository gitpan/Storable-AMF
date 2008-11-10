use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF;
use Test::More tests => 2;

use Cwd;
use GrianUtils;
use File::Spec;
use FindBin;
sub data{
	my $file = File::Spec->catfile( $FindBin::Bin, $_[0] );
	my @values = Storable::thaw(GrianUtils->my_readfile($file));
	if (@values> 1) {
		print STDERR "many returned values\n";
	};
	return {data =>	( @values ? $values[0] : "DEEDBEEF")};
};

sub get_file{
	my $file = File::Spec->catfile( $FindBin::Bin, $_[0] );
	return GrianUtils->my_readfile($file);
}

sub serialize{
	my @values = Storable::AMF::freeze($_[0]);
	if (@values > 1) {
		print STDERR "many returned values\n";
	}
	return $values[0];
}
ok(defined(serialize([0])), "xxx");
ok(defined(Storable::AMF::freeze([0])), "xxxx1");

