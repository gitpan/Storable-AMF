use lib 't';
use ExtUtils::testlib;
use Storable::AMF3 qw(freeze thaw ref_lost_memory ref_destroy);
use Scalar::Util qw(refaddr);
use GrianUtils qw(ref_mem_safe);
use strict;
use warnings;
no warnings 'once';
use Data::Dumper;
our $msg;
sub tt(&);
sub tt(&){
    my $sub = shift;
    my $s = ref_mem_safe( $sub );
    $msg = $s;
    return $s if $s;
    return undef;
}


my @item ;
@item= map {grep { $_!~m/\./ } GrianUtils->my_readdir("t/$_/") } qw( AMF0);


my @objs;
for my $item (@item){
	my $eval  = GrianUtils->my_readfile("$item");
	no strict;
	my $s = eval $eval;
	die $@ if $@;
    push (@objs, $item), next if !ref_lost_memory($s);
}

my $total = @objs*4 + @item;
eval "use Test::More tests=>$total;";
warn $@ if $@;


TEST_LOOP: for my $item (@item){
	my $image_amf3 = GrianUtils->my_readfile("$item.amf3");
	my $image_amf0 = GrianUtils->my_readfile("$item.amf0");
	my $eval  = GrianUtils->my_readfile("$item");
	if ($eval =~m/use\s+utf8/) {
		SKIP: {
			no strict;
			skip("utf8 convert is not supported mode", 6);
		}
	}
	else {
		no strict;
		
		my $obj = eval $eval;
        use strict;

        my $freeze = freeze $obj;        
        
        ok(tt { my $a = thaw $image_amf0;ref_destroy($a); 1}, "thaw destroy $item - $msg");
	}
}

TEST_LOOP: for my $item (@objs){
	my $image_amf3 = GrianUtils->my_readfile("$item.amf3");
	my $image_amf0 = GrianUtils->my_readfile("$item.amf0");
	my $eval  = GrianUtils->my_readfile("$item");
	if ($eval =~m/use\s+utf8/) {
		SKIP: {
			no strict;
			skip("utf8 convert is not supported mode", 6);
		}
	}
	else {
		no strict;
		
		my $obj = eval $eval;
        use strict;

        my $freeze = freeze $obj;        
        my $a1 = $freeze;
        my $a2 = $freeze;
        
        ok(tt { my $a = thaw $image_amf3;1}, "thaw $item - $msg");
        #ok(tt { my $a = thaw $freeze}, "thaw $item - $msg");
        ok(tt { my $a = freeze $obj;1},  "freeze $item - $msg");
        ok(tt { my $a = thaw freeze $obj;1},  "thaw freeze $item - $msg");
        #ok(tt { my $a = \freeze thaw $image_amf3},  "freeze thaw $item - $msg");
        ok(tt { my $a = freeze thaw $freeze;1},  "freeze thaw $item - $msg");
	}
}


