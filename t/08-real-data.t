use lib 't';
use strict;
use warnings;
use Storable::AMF0 qw(freeze thaw retrieve);
use GrianUtils;
use subs 'skip';

my @item = grep { $_!~m/\./ } GrianUtils->my_readdir('t/08/AMF');

#print join "\n", @item;

my $total = @item*2;
#use Test::More tests => 16;
eval "use Test::More tests=>$total;";
warn $@ if $@;

for my $item (@item){
	my $obj = retrieve("$item.amf0");
	my $image = GrianUtils->my_readfile("$item.amf0");
	my $eval  = GrianUtils->my_readfile("$item");
	if ($eval =~m/use\s+utf8/) {
		SKIP: {
			skip "Convetation on utf8 not supported", 2;
		}
	}
	else {
		ok(defined($obj), $item);	
		no strict;
		is_deeply($obj, eval $eval, $item.":\n\t$eval");
	}
}


