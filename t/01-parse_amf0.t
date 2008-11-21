use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF;
use Test::More tests => 14;

use GrianUtils;
use File::Spec;
sub data{
	my $file = File::Spec->catfile( "t/", $_[0] );
	my @values = Storable::AMF::thaw(GrianUtils->my_readfile($file));
	if (@values> 1) {
		print STDERR "many returned values\n";
	};
	return {data =>	( @values ? $values[0] : "DEEDBEEF")};
};

is_deeply(data('data/amf0/number'), {data => 123}, "read number");
is_deeply(data('data/amf0/boolean_true'), {data => 1}, "read boolean_true");
is_deeply(data('data/amf0/boolean_false'), {data => 0}, "read boolean_false");

is_deeply(data('data/amf0/string'), {data => "foo"}, "read string");

is_deeply(data('data/amf0/object'), {data => {"foo" => "bar"}}, "read object");
is_deeply(data('data/amf0/object2'), 
{data => 
	{
	array => ['foo', 'bar'], 
	hash => {"foo" => "bar"}
	}}, 
	"read object2");
is_deeply(data('data/amf0/null_object'), {data => {}}, "read null object");
is_deeply(data('data/amf0/null'), {data => undef}, "null");
is_deeply(data('data/amf0/undefined'), {data => undef}, "undefined");
our $object  = data('data/amf0/reference');
is_deeply($object, {data => {obj1=> {foo=>'bar'}, obj2=>{foo=>'bar'}}}, "reference object");
my $o_com = { ary => [qw(a b c)], obj => {foo=>'bar'}};
my @nested = (ary => $o_com->{ary}, obj => $o_com->{obj});

is_deeply(data('data/amf0/reference_nested'), 
	{data => 
		{obj => $o_com->{obj}, 
		 obj2 => $o_com->{obj}, 
		 ary => $o_com->{ary}, 
		 nested => {@nested}}
	},
"nested reference");
is_deeply(data('data/amf0/ecma_array'), {data => {0=>'foo', bar=> 'baz'}}, "ecma_array");# 13
is_deeply(data('data/amf0/strict_array'), {data => ['foo', bar=> 'baz']}, "strict_array");# 14
is_deeply(data('data/amf0/date'), {data => 1216717318745}, "date");# 15
