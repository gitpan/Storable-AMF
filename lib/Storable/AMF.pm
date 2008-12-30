package Storable::AMF;
#use 5.008008;
use strict;
use warnings;
use Fcntl qw(:flock);
use Storable::AMF0;
our $VERSION = '0.39';

require Exporter;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw(
	freeze thaw	dclone retrieve lock_retrieve lock_store lock_nstore store ref_lost_memory ref_destroy
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

no strict 'refs';
*{"Storable::AMF::$_"} = *{"Storable::AMF0::$_"} for @{$EXPORT_TAGS{'all'}};

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Storable::AMF - Perl extension for serialize/deserialize AMF0/AMF3 data

=head1 SYNOPSIS

  use Storable::AMF0 qw(freeze thaw); # or use Storable::AMF3 qw(freeze thaw)l for AMF3 format

  $amf0 = freeze($perl_object);
  $perl_object = thaw($amf0);

	
  # Store/retrieve to disk amf0 data
	
  store $perl_object, 'file';
  $restored_perl_object = retrieve 'file';


  use Storable::AMF0 qw(nstore freeze thaw dclone);

  # Network order: Due to spec of AMF0 format objects (hash, arrayref) stored in network order.
  # and thus nstore and store are synonyms 

  nstore \%table, 'file';
  $hashref = retrieve('file'); 

  
  # Advisory locking
  use Storable::AMF0 qw(lock_store lock_nstore lock_retrieve)
  lock_store \%table, 'file';
  lock_nstore \%table, 'file';
  $hashref = lock_retrieve('file');

=cut

=head1 DESCRIPTION

This module is (de)serializer for Adobe's AMF0/AMF3 (Action Message Format ver 0-3).
This is only module and it recognize only AMF data. 
Almost all function implemented in C for speed. 
And some cases faster then Storable( for me always)

=cut

=head1 EXPORT
  
  None by default.

=cut
=head1 MOTIVATION

There are several modules for work with AMF data and packets written in perl, but them are lack a speed.
This module writen in C for speed. Also this package allow freeze and thaw AMF3 data which is nobody do.

=cut
=head1 ERROR REPORTING
    In case of errors functions freeze and thaw returns undef and set $@ error description. 
    (Error description at the moment is criptic, forgive me..)

=cut
=head1 FUNCTIONS
=cut

=over

=item freeze($obj) 
  --- Serialize perl object($obj) to AMF, and return AMF data

=item thaw($amf0)
  --- Deserialize AMF data to perl object, and return the perl object

=item store $obj, $file
  --- Store serialized AMF0 data to file

=item nstore $obj, $file
  --- Same as store

=item retrieve $obj, $file
  --- Retrieve serialized AMF0 data from file

=item lock_store $obj, $file
  --- Same as store but with Advisory locking

=item lock_nstore $obj, $file
  --- Same as lock_store 

=item lock_retrieve $file
  --- Same as retrieve but with advisory locking

=item dclone $file
  --- Deep cloning data structure

=item ref_destroy $obj
  --- Deep decloning data structure
  --- safely destroy cloned object or any object 

=item ref_lost_memory $obj
  --- test if object contain lost memory fragments inside.
  (Example do { my $a = []; @$a=$a; $a})

=back

=head1 NOTICE

  Storable::AMF is currently is at development stage. 

=cut

=head1 LIMITATION

At current moment and with restriction of AMF0/AMF3 format referrences to scalar are not serialized,
and can't/ may not serialize tied variables.
And dualvars (See Scalar::Util) are serialized as string value.
Freezing CODEREF, IO, Regexp, REF, GLOB, SCALAR referenses restricted.

=head1 TODO

Add some options to functions.

Document freezing and thawing XMLDocument, XML, Date
May be add some IO and packet manipulated function (SEE AMF0/AMF3 at Adobe)


=head1 SEE ALSO

L<Data::AMF>, L<Storable>, L<Storable::AMF0>, L<Storable::AMF3>

=head1 AUTHOR

Anatoliy Grishaev, <grian at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by A. G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
=cut
