use Test::More tests => 6;
use lib 't';
use ExtUtils::testlib;
use Storable::AMF0 qw(ref_lost_memory ref_destroy);
use Scalar::Util qw(refaddr);
use strict;
use warnings;

my $a1 = [];
ok(! ref_lost_memory([]));
ok(! ref_lost_memory([[]]));
ok(! ref_lost_memory([{}]));
ok(! ref_lost_memory([$a1, $a1]));

my $a2 = []; @$a2=$a2;

ok( ref_lost_memory($a2));

ref_destroy($a2);
ref_destroy("");
ref_destroy(1);
ref_destroy({});
ref_destroy([]);

my $addr;
my %c;
for (1..20)
{
    my $a3 = [];
    @$a3= $a3;
    $addr = refaddr $a3;
    ref_destroy($a3);
    #say STDERR refaddr($a3) unless $c{refaddr $a3}++;
}

{
    my $a3 = [];
    @$a3= $a3;
    is($addr, refaddr $a3);
    $addr = refaddr $a3;
}




