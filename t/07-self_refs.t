use strict;
use Test::More tests=>21;
use warnings;

use Storable::AMF qw(freeze thaw);

my @objects = (
	do { 
		my $a = [];
		$a->[0]=$a;
		$a;
	},
	do {
		my $a = {};
		$a->{'a'} = $a;
		$a;
	},
	do {
		my ($a, $b) = ([], {});
		@$a = ($b, $b);
		$a;
	},
	do {
		my ($a, $b) = ([], {});
		@$a = ($b, $b, $a, $a);
		$a;
	},
	do {
		my ($a, $b) = ([], {});
		@{$b}{qw(a b c d)} = ($b, $b, $a, $a);
		$b;
	},
	do {
		my ($a, $b) = ([], {});
		@{$a} = ($a, $b);
		$a
	},
	do {
		my ($a, $b) = ([], {});
		@{$a} = ($b, $a);
		$a
	},
);
ok(freeze $_) foreach @objects;
ok( thaw freeze $_) foreach @objects;

is_deeply(thaw(freeze $_), $_) foreach @objects;

