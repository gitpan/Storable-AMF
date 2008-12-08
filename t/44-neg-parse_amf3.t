use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF3 qw(freeze thaw);
use GrianUtils;
use Data::Dumper;
my @item ;
@item= map {grep { $_!~m/\./ } GrianUtils->my_readdir("t/$_/") } qw( AMF0);

my $total = @item*2;
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
        use strict;

        my $freeze = freeze $obj;        
        my $a1 = $freeze;
        my $a2 = $freeze;
        chop($a1);
        $a2.='\x01';

		ok(! defined(thaw ($a1)), "fail of trunced ($item) $eval");
		ok(! defined(thaw ($a2)), "fail of extra   ($item) $eval");

	}
}


