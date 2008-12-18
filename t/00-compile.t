# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-AMF-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN { 
	$totals =  3;
	eval "use Test::More tests => $totals";

	use_ok('Storable::AMF');
	use_ok('Storable::AMF0');
	use_ok('Storable::AMF3');
	};
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

