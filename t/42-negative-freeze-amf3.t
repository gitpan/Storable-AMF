use ExtUtils::testlib;
use strict;
use warnings;
use Test::More tests=>12;
use Storable::AMF3 qw(freeze);
use Data::Dumper;
ok(! defined( scalar freeze($_)), ref $_) for sub {};
ok(! defined( scalar freeze($_)), ref $_) for \my $a;
ok(! defined( scalar freeze($_)), ref $_) for bless sub {}, 'a';
ok(! defined( scalar freeze($_)), ref $_) for bless \my $b, 'a';
ok(! defined( scalar freeze($_)), ref $_) for \*freeze;
ok(! defined( scalar freeze($_)), ref $_) for bless \*freeze, 'a';
my $d = \$a;
ok(! defined( scalar freeze($_)), ref $_) for \$d;
ok(! defined( scalar freeze($_)), ref $_) for bless \$d, 'a';

ok(! defined( scalar freeze($_)), ref $_) for qr/\w+/;
ok(! defined( scalar freeze($_)), ref $_) for bless qr/\w+/, 'a';
ok(! defined( scalar freeze($_)), ref $_) for *STDERR{IO};
ok(! defined( scalar freeze($_)), ref $_) for bless *STDERR{IO}, 'a';


