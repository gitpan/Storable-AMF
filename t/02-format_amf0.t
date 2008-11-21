use lib "t";
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF;
use Test::More tests => 13;

use GrianUtils;
use File::Spec;
our $TestDir = "t";
sub data{
	my $file = File::Spec->catfile( $TestDir, $_[0] );
	my @values = Storable::thaw(GrianUtils->my_readfile($file));
	if (@values> 1) {
		print STDERR "many returned values\n";
	};
	return {data =>	( @values ? $values[0] : "DEEDBEEF")};
};

sub to_hex{
	map { unpack "H*", $_ } $_[0];	
}

sub get_file{
 	my $file; #= File::Spec->catfile( $FindBin::Bin, $_[0] );
 	$file = File::Spec->catfile($TestDir, $_[0]);
 	return GrianUtils->my_readfile($file);
 }

sub serialize{
	my @values = Storable::AMF::freeze($_[0]);
	if (@values > 1) {
		print STDERR "many returned values\n";
	}
	elsif (! @values) {
		print STDERR "Failed freeze\n";
	}
	return $values[0];
}

my $data = get_file('data/amf0/number');

is(to_hex(serialize(123)), to_hex($data), " ok" );
our %objects = (
		'123', get_file('data/amf0/number'),
		"foo", get_file('data/amf0/string'),
);
foreach my $obj (keys %objects){
	my $data = serialize($obj);
	is( to_hex($data), to_hex($objects{$obj}), "i50 $obj");
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
my $c=0;

foreach my $obj (@objects){
	my $data = serialize($obj);
	is_deeply( $obj, Storable::AMF::thaw($data), "obj $c");
	++$c;

}
