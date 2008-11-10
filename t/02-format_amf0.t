use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF;
use Test::More tests => 13;

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

my $data = get_file('data/amf0/number');
is($data, serialize(123)," ok" );
our %objects = (
		123, get_file('data/amf0/number'),
		"foo", get_file('data/amf0/string'),
);
foreach my $obj (keys %objects){
	my $data = serialize($obj);
	is_deeply( $data, $objects{$obj});
}
is_deeply(serialize({foo=>'bar'}), get_file('data/amf0/object'));
is_deeply(serialize({ array => [foo=>'bar'], hash => {foo => "bar"}}), get_file('data/amf0/object2'));
our @objects = (
		123, 
		"foo",
		"bar",
		undef,
		[1,3,4,5,],
		[23423, {}, 23423],
		{foo=>'bar'},
		{fooo => [ "bar" => 2,1,4, {gkljtlt => 1}], fasdfasd=> 12312},
		);
foreach my $obj (@objects){
	my $data = serialize($obj);
	is_deeply( $obj, Storable::AMF::thaw($data));
}
