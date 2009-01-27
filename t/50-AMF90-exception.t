use lib 't';
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw ref_lost_memory ref_destroy);
use Scalar::Util qw(refaddr);
use GrianUtils qw(ref_mem_safe);
use strict;
use warnings;
no warnings 'once';
use Data::Dumper;
#use Test::More tests=>1;
 eval "use Test::More tests=>1;";

our $msg = '
080000000300066c656e677468004008000000000000
0001300200036e65740001310200056c6f67696e0001
320300067469636b65740200204c614a6d7a586e6945
666f5167476b66706e566c5672647964745372534d50
4200046d61696c020009796140746f682e7275000009
000009
';
$msg=~s/\W+//g;
our $VAR1 = [
          'net',
          'login',
          {
            'mail' => 'ya@toh.ru',
            'ticket' => 'LaJmzXniEfoQgGkfpnVlVrdydtSrSMPB'
          }
        ];


my $comp =  thaw( pack "H*", $msg);
is_deeply( $comp, $VAR1 , "Bug in Flash 9.0")
