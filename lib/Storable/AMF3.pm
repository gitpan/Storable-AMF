package Storable::AMF3;
#use 5.008008;
use strict;
use warnings;
use Fcntl qw(:flock);
our $VERSION = '0.40';
use subs qw(freeze thaw);
require Exporter;
use Carp qw(carp);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw(
	freeze thaw	dclone retrieve lock_retrieve lock_store lock_nstore store 
    ref_destroy ref_lost_memory
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);


sub retrieve{
	my $file = shift;
	open my $fh, "<", $file or die "Can't open file \"$file\" for read.";
	my $buf;
	read $fh, $buf, -s $fh;
	close($fh);
	return thaw($buf);
}

sub lock_retrieve{
	my $file = shift;
	open my $fh, "<", $file or die "Can't open file \"$file\" for read.";
	flock $fh, LOCK_SH;
	my $buf;
	read $fh, $buf, -s $fh;
	flock $fh, LOCK_UN;
	close($fh);
	return thaw($buf);
}
sub store{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	truncate $fh, 0;
	#print $fh freeze($object);
    my $freeze;
    carp "Bad object" unless defined ($freeze = freeze $object);
    print $fh $freeze if defined($freeze);
	close($fh) and  defined $freeze;
}

sub lock_store{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	flock $fh, LOCK_EX;
	truncate $fh, 0;
	#print $fh freeze($object);
    my $freeze;
    carp "Bad object" unless defined ($freeze = freeze $object);
    print $fh $freeze if defined($freeze);
	flock $fh, LOCK_UN;
	close($fh) and defined $freeze;
}

sub nstore{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	truncate $fh, 0;
	#print $fh freeze($object);
    my $freeze;
    carp "Bad object" unless defined ($freeze = freeze $object);
    print $fh $freeze if defined($freeze);
	close($fh) and defined $freeze;
}

sub lock_nstore{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	flock $fh, LOCK_EX;
	truncate $fh, 0;
	#print $fh freeze($object);
    my $freeze;
    carp "Bad object" unless defined ($freeze = freeze $object);
    print $fh $freeze if defined($freeze);
	flock $fh, LOCK_UN;
	close($fh) and defined $freeze;
}
#~ sub dclone{
#~ 	my $object = shift;
#~ 	return thaw(treeze $_[0]);
#~ }
require XSLoader;
XSLoader::load('Storable::AMF', $VERSION);
no warnings;
no strict 'refs';
#*Storable::AMF3::dclone = *Storable::AMF0::dclone;
*{"Storable::AMF3::$_"} = *{"Storable::AMF0::$_"} for qw(dclone ref_lost_memory ref_destroy);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Storable::AMF3 - Perl extension for serialize/deserialize AMF3 data

=head1 SYNOPSIS

  use Storable::AMF3 qw(freeze thaw); 

  $amf3 = freeze($perl_object);
  $perl_object = thaw($amf3);

	
  # Store/retrieve to disk amf3 data
	
  store $perl_object, 'file';
  $restored_perl_object = retrieve 'file';


  use Storable::AMF3 qw(nstore freeze thaw dclone);

  # Network order: Due to spec of AMF3 format objects (hash, arrayref) stored in network order.
  # and thus nstore and store are synonyms 

  nstore \%table, 'file';
  $hashref = retrieve('file'); 

  
  # Advisory locking
  use Storable::AMF3 qw(lock_store lock_nstore lock_retrieve)
  lock_store \%table, 'file';
  lock_nstore \%table, 'file';
  $hashref = lock_retrieve('file');

=cut

=head1 DESCRIPTION

This module is (de)serializer for Adobe's AMF3 (Action Message Format ver 3).
This is only module and it recognize only AMF data. 
Almost all function implemented in C for speed. 
And some cases faster then Storable( for me always)

=cut

=head1 EXPORT
  
  None by default.

=cut
=head1 FUNCTIONS
=cut

=over

=item freeze($obj) 
  --- Serialize perl object($obj) to AMF, and return AMF data

=item thaw($amf3)
  --- Deserialize AMF data to perl object, and return the perl object

=item store $obj, $file
  --- Store serialized AMF3 data to file

=item nstore $obj, $file
  --- Same as store

=item retrieve $obj, $file
  --- Retrieve serialized AMF3 data from file

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

  Storable::AMF is currently is alpha development stage. 

=cut

=head1 LIMITATION

At current moment and with restriction of AMF3 format referrences to scalar are not serialized,
and BigEndian machines are not supported, 
and can't/ may not serialize tied variables.

=head1 SEE ALSO

L<Data::AMF>, L<Storable>, L<Storable::AMF3>

=head1 AUTHOR

Anatoliy Grishaev, <grian at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by A. G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
=cut
