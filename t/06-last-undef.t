use strict;
use warnings;
use Storable;
use Storable::AMF;
use Test::More tests=>1;

#Storable::AMF::freeze({a=>1});
ok(Storable::AMF::freeze(Storable::retrieve('t/data/test-06')) );


