# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-AMF-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
my @methods;

use ExtUtils::testlib;

use Storable::AMF;
use Storable::AMF0;
use Storable::AMF3;
use Scalar::Util qw(refaddr);
@methods = @Storable::AMF::EXPORT_OK;
$totals = @methods * 3  + 1 * @methods;
eval "use Test::More tests => $totals";

for my $module (qw(Storable::AMF Storable::AMF0 Storable::AMF3)){
	ok($module->can($_), "$module can $_") for @methods;
}

my ($m, $n) = qw(Storable::AMF Storable::AMF0);

is(refaddr $m->can($_), refaddr $n->can($_), "identity for $_") for @methods;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

