package Storable::AMF0;
#use 5.008008;
use strict;
use warnings;
use Fcntl qw(:flock);
our $VERSION = '0.21';
use subs qw(freeze thaw);

require Exporter;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw(
	freeze thaw	dclone retrieve lock_retrieve lock_store lock_nstore store
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

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
	print $fh freeze($object);
	close($fh);
}

sub lock_store{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	flock $fh, LOCK_EX;
	truncate $fh, 0;
	print $fh freeze($object);
	flock $fh, LOCK_UN;
	close($fh);
}

sub nstore{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	truncate $fh, 0;
	print $fh freeze($object);
	close($fh);
}

sub lock_nstore{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	flock $fh, LOCK_EX;
	truncate $fh, 0;
	print $fh freeze($object);
	flock $fh, LOCK_UN;
	close($fh);
}
#~ sub dclone{
#~  	my $object = shift;
#~  	return thaw(freeze($object));
#~ }
require XSLoader;
XSLoader::load('Storable::AMF', $VERSION);
#no strict 'refs';
#*{"Storable::AMF0::$_"} = *{"Storable::AMF::$_"} for @{$EXPORT_TAGS{'all'}};


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Storable::AMF0 - Perl extension for serialize/deserialize AMF0 data

=head1 SYNOPSIS

  use Storable::AMF0 qw(freeze thaw);

  $amf0 = freeze($perl_object);
  $perl_object = thaw($amf0);

	
  # Store/retrieve to disk amf0 data
	
  use Storable::AMF0 qw(store retrieve);
  store $perl_object, 'file';
  $restored_perl_object = retrieve 'file';


  use Storable::AMF qw(nstore freeze thaw dclone);

  # Network order: Due to spec of AMF0 format objects (hash, arrayref) stored in network order.
  # and thus nstore and store are synonyms 

  nstore \%table, 'file';
  $hashref = retrieve('file');  # There is NO nretrieve()

  
  # Advisory locking
  use Storable::AMF qw(lock_store lock_nstore lock_retrieve)
  lock_store \%table, 'file';
  lock_nstore \%table, 'file';
  $hashref = lock_retrieve('file');

=head1 DESCRIPTION

This module is (de)serializer for Adobe's AMF (Action Message Format).
This is only module and it recognize only AMF data. 
Core function implemented in C. And some cases faster then Storable( for me always)

=head2 EXPORT

None by default.

=head1 EXPORT_OK
=cut
=head2 freeze($obj) 
  Serialize perl object($obj) to AMF, and return AMF data

=head2 thaw($amf0)
  Deserialize AMF data to perl object, and return the perl object
=head2 store $obj, $file
  Store serialized AMF0 data to file
=head2 nstore $obj, $file
 Same as store
=head2 retrieve $obj, $file
=head2 lock_store $obj, $file
  Same as store but with Advisory locking
=head2 lock_nstore $obj, $file
  Same as lock_store 
=head2 lock_retrieve $file
  Same as retrieve but with advisory locking
=cut

=head1 NOTICE

  Storable::AMF is currently at alpha development stage. 
=cut

=head1 LIMITATION

At current moment and with restriction of AMF0/AMF3 format referrences to scalar are not serialized,
and can't/ may not serialize tied variables.

=head1 FEATURES

	Due bug of Macromedia 'XML' type not serialized properly (it loose all atributes for AMF0) 
	For AMF0 has to use XMLDocument type.

=head1 SEE ALSO

L<Data::AMF>, L<Storable>

=head1 AUTHOR

Anatoliy Grishaev, <gtoly@combats.ru>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by A. G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.
=cut
