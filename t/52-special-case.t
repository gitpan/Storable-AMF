use lib 't';
use ExtUtils::testlib;
use strict;
use warnings;
use Storable::AMF qw(freeze thaw);
use Data::Dumper;
use Test::More tests=>2;
my @r = ();


eval{
    thaw(undef);
};
ok($@);
eval{
    Storable::AMF3::thaw(undef);
};
ok($@);
*{TODO} = *Test::More::TODO;
