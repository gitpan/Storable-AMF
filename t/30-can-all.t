# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-AMF-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
my @methods;

use Storable::AMF;
use Storable::AMF0;
use Storable::AMF3;
@methods = @Storable::AMF::EXPORT_OK;
$totals = @methods * 3 ;
eval "use Test::More tests => $totals";

for my $module (qw(Storable::AMF Storable::AMF0 Storable::AMF3)){
	ok($module->can($_), "$module can $_") for @methods;
}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

