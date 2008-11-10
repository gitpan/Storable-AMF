package Storable::AMF3;

use 5.008008;
use strict;
use warnings;
use Fcntl qw(:flock);
our $VERSION = '0.12';

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::AMF::XS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	freeze thaw	dclone retrieve lock_retrieve lock_store lock_nstore store
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
#~ 	my $object = shift;
#~ 	return thaw(treeze $_[0]);
#~ }
require XSLoader;
XSLoader::load('Storable::AMF', $VERSION);
no warnings;
*Storable::AMF3::dclone = *Storable::AMF::dclone;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Storable::AMF - Perl extension for serialize/deserialize AMF date

=head1 SYNOPSIS

  use Storable::AMF qw(freeze thaw);

  store \%table, 'file';
  $hashref = retrieve('file');

  use Storable::AMF qw(nstore store_fd nstore_fd freeze thaw dclone);

  # Network order: always store in network order 
  # and nstore and store are synonyms 

  nstore \%table, 'file';
  $hashref = retrieve('file');  # There is NO nretrieve()

  # Serializing to memory
  $serialized = freeze \%table;
  %table_clone = %{ thaw($serialized) };
  
  # Advisory locking
  use Storable::AMF qw(lock_store lock_nstore lock_retrieve)
  lock_store \%table, 'file';
  lock_nstore \%table, 'file';
  $hashref = lock_retrieve('file');

=head1 DESCRIPTION

This module is (de)serializer for Adobe's AMF (Action Message Format).
This is only module and it recognize only AMF data. 
Core function implemented in C. And some cases faster then Storable( for me alwaye)

=head2 EXPORT

None by default.

=head1 METHOD
=head2 freeze($obj) 
Serialize perl object($obj) to AMF, and return AMF data

=head2 thaw($amf0)
Deserialize AMF data to perl object, and return the perl object

=head1 NOTICE

Storable::AMF is currently is very alpha development stage/
This current version is not support AMF3. 

=head1 LIMITATION

At current moment freeze not support for nested reference in object and utf8 string not marked 
by default. It not serialize tied variables.


=head1 SEE ALSO

L<Data::AMF>, L<Storable>

=head1 AUTHOR

Anatoliy Grishaev, <grian at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by A. G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
