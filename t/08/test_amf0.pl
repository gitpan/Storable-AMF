use strict;
use warnings;
use Storable::AMF qw(freeze thaw retrieve);
use Data::Dumper;
use GrianUtils;

my @item = grep { $_!~m/\./ } GrianUtils->my_readdir('AMF');

print join "\n", @item;

my $total = @item*2;
#use Test::More tests => 16;
eval "use Test::More tests=>$total;";
warn $@ if $@;

for my $item (@item){
	my $obj = retrieve("$item.amf0");
	my $image = GrianUtils->my_readfile("$item.amf0");
	my $eval  = GrianUtils->my_readfile("$item");
	ok(defined($obj), $item);	
	no strict;
	is_deeply($obj, eval $eval, $item.":\n\t$eval");
}


