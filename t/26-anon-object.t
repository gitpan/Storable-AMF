use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF qw(freeze thaw retrieve);
use GrianUtils;

my @item = grep { $_!~m/\./ } GrianUtils->my_readdir('t/26/');
#@item = grep { /n_-?\d+$/ } @item;

#print join "\n", @item;

my $total = @item*2;
#use Test::More tests => 16;
eval "use Test::More tests=>$total;";
warn $@ if $@;



for my $item (@item){
	my $eval  = GrianUtils->my_readfile("$item");
	eval $eval;
	die $@ if $@;
}
for my $item (@item){
	my $image_amf3 = GrianUtils->my_readfile("$item.amf3");
	my $image_amf0 = GrianUtils->my_readfile("$item.amf0");
	my $eval  = GrianUtils->my_readfile("$item");
	no strict;
	
	my $obj = eval $eval;
	my $new_obj;
	is_deeply(unpack("H*", Storable::AMF3::freeze($obj)), unpack( "H*",$image_amf3), "name: ". $item.":".$eval);
	#print STDERR Data::Dumper->Dump([$item]), "\n";
	is_deeply($new_obj = Storable::AMF3::thaw($image_amf3), $obj, "thaw name: ". $item. ":".$eval);
	#print STDERR Data::Dumper->Dump([unpack("H*", Storable::AMF3::freeze(eval $eval)), unpack( "H*",$image_amf3)]), "\n";
}


