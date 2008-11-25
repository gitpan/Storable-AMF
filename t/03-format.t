use lib "t";
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF;
use Test::More tests => 4;

use GrianUtils;
use File::Spec;

sub serialize{
	my @values = Storable::AMF::freeze($_[0]);
	if (@values > 1) {
		print STDERR "many returned values\n";
	}
	return $values[0];
}
ok(defined(serialize([0])), "xxx");
ok(defined(Storable::AMF::freeze([0])), "xxxx1");

my $long = 'x' x 70000;

ok(defined(serialize($long)), "Can serialize big string");
is(Storable::AMF::thaw(serialize($long)), $long, "dup long string");



