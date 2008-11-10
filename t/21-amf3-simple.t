use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF qw(freeze thaw retrieve);
use Data::Dumper;
use GrianUtils;

my @item = grep { $_!~m/\./ } GrianUtils->my_readdir('t/08/AMF');
@item = grep { /n_-?\d+$/ } @item;

#print join "\n", @item;

my $total = @item*2;
#use Test::More tests => 16;
$total = 2+2*@item;
eval "use Test::More tests=>$total;";
warn $@ if $@;
ok(Storable::AMF3->can("freeze"));
ok(Storable::AMF3->can("thaw"));

for my $item (@item){
	my $obj = retrieve("$item.amf0");
	my $image_amf3 = GrianUtils->my_readfile("$item.amf3");
	my $image_amf0 = GrianUtils->my_readfile("$item.amf0");
	my $eval  = GrianUtils->my_readfile("$item");
	no strict;
	is(unpack("H*", Storable::AMF3::freeze(eval $eval)), unpack( "H*",$image_amf3), "freeze number: ". eval $eval);
	is(Storable::AMF3::thaw($image_amf3), eval($eval), "thaw number: ".eval $eval);
}


