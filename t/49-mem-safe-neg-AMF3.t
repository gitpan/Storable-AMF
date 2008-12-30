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
    push (@objs, $item), next if 1 or !ref_lost_memory($s);
}
@item = @objs;
my $total = @item*2;
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

        my $freeze = $image_amf3;        
        my $a1 = $freeze.'0';
        my $a2 = $freeze;
        chop ($a2);
        
        ok(tt { my $a = thaw ( $a1 );},  "thaw $item extra - $msg");
        ok(tt { my $a = thaw ( $a2 );},  "thaw without one char $item - $msg");
	}
}


