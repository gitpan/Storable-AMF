use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF qw(freeze thaw retrieve);
use GrianUtils;
my @item ;
@item= map {grep { $_!~m/\./ } GrianUtils->my_readdir("t/$_/") } qw(08/AMF 25 26 27);

#@item = grep { /n_-?\d+$/ } @item;

#print join "\n", @item;
#@item = grep /complex/,@item;
my $total = @item*4;
#use Test::More tests => 16;
eval "use Test::More tests=>$total;";
warn $@ if $@;



for my $item (@item){
	my $eval  = GrianUtils->my_readfile("$item");
	no strict;
	eval $eval;
	die $@ if $@;
}
TEST_LOOP: for my $item (@item){
	my $image_amf3 = GrianUtils->my_readfile("$item.amf3");
	my $image_amf0 = GrianUtils->my_readfile("$item.amf0");
	my $eval  = GrianUtils->my_readfile("$item");
	if ($eval =~m/use\s+utf8/) {
		SKIP: {
			no strict;
			skip("utf8 convert is not supported mode", 4);
		}
	}
	else {
		no strict;
		
		my $obj = eval $eval;
		my $new_obj;
		ok(defined(Storable::AMF3::freeze($obj)), "defined ($item) $eval");
		ok(defined(Storable::AMF3::thaw(Storable::AMF3::freeze($obj))));
		is_deeply($new_obj = Storable::AMF3::thaw($image_amf3), $obj, "thaw name: ". $item. "(amf3):\n\n".$eval);
		if ($item =~m/complex/){
			#print STDERR Data::Dumper->Dump([$new_obj, $obj, unpack( "H*", $image_amf3), ]);
		}
		is(ref $new_obj, ref $obj, "type of: $item :: $eval");
		#print STDERR Data::Dumper->Dump([unpack("H*", Storable::AMF3::freeze(eval $eval)), unpack( "H*",$image_amf3)]), "\n";

	}
}


