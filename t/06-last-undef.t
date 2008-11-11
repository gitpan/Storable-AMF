use strict;
use warnings;
use Storable::AMF;
use Test::More tests=>1;

#Storable::AMF::freeze({a=>1});
my @a;$a[5] =1;
#ok(Storable::AMF::freeze(Storable::retrieve('t/data/test-06')) );
ok(Storable::AMF::freeze(\@a));


