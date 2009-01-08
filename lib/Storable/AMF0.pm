package Storable::AMF0;
#use 5.008008;
use strict;
use warnings;
use Fcntl qw(:flock);
our $VERSION = '0.40';
use subs qw(freeze thaw);
use Scalar::Util qw(refaddr reftype); # for ref_circled

require Exporter;
use Carp qw(carp);
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw(
	freeze thaw	dclone 
    retrieve lock_retrieve lock_store lock_nstore store
    ref_lost_memory ref_destroy
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
	#print $fh freeze($object);
    my $freeze = freeze($object);
    carp "Bad object" unless defined $freeze;
	print $fh $freeze if defined $freeze;
	close($fh) and  defined $freeze;;
}

sub lock_store{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	flock $fh, LOCK_EX;
	truncate $fh, 0;
	#print $fh freeze($object);
    my $freeze = freeze($object);
    carp "Bad object" unless defined $freeze;
	print $fh $freeze if defined $freeze;
	flock $fh, LOCK_UN;
	close($fh) and  defined $freeze;;
}

sub nstore{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	truncate $fh, 0;
	#print $fh freeze($object);
    my $freeze = freeze($object);
    carp "Bad object" unless defined $freeze;
	print $fh $freeze if defined $freeze;
	close($fh) and  defined $freeze;;
}

sub lock_nstore{
	my $object = shift;
	my $file   = shift;
	open my $fh, "+>", $file or die "Can't open file \"$file\" for write.";
	flock $fh, LOCK_EX;
	truncate $fh, 0;
    my $freeze = freeze($object);
    if ( defined $freeze ) {
        print $fh $freeze;
    };
	flock $fh, LOCK_UN;
	close($fh) and  defined $freeze;
}

sub _ref_selfref{
    my $obj_addr =shift;
    my $value = shift;
    my $addr  = refaddr $value;
    return unless defined $addr;
    if ( reftype $value eq 'ARRAY'){
            
            return $$obj_addr{$addr} if exists $$obj_addr{$addr}; 
            $$obj_addr{$addr} = 1;
            _ref_selfref($obj_addr, $_) && return 1  for @$value;
            $$obj_addr{$addr} = 0;
        }
    elsif ( reftype $value eq 'HASH'){

            
            return $$obj_addr{$addr} if exists $$obj_addr{$addr}; 
            $$obj_addr{$addr} = 1;
            _ref_selfref($obj_addr, $_) && return 1  for values %$value;
            $$obj_addr{$addr} = 0;
        }
    else {
            return ;
    };

    return ;
}

sub ref_lost_memory{
    my $ref = shift;
    my %obj_addr;
    return _ref_selfref(\%obj_addr, $ref);
}

sub ref_destroy{
    my $ref = shift;
    my %addr;
    return unless (refaddr $ref);
    my @r;
    if (reftype $ref eq 'ARRAY'){
        @r = @$ref;
        @$ref =();
        ref_destroy($_) for @r;
    }
    elsif (reftype  $ref eq 'HASH'){
        @r = values %$ref;
        %$ref =();
        ref_destroy($_) for @r;
    }
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

Storable::AMF0 - Perl extension for serialize/deserialize AMF0/AMF3 data

=head1 SYNOPSIS

  use Storable::AMF0 qw(freeze thaw); # or use Storable::AMF3 qw(freeze thaw) for AMF3 format

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
This is only module and it recognize only AMF0 data. 
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
  --- Serialize perl object($obj) to AMF0, and return AMF0 data

=item thaw($amf0)
  --- Deserialize AMF0 data to perl object, and return the perl object

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

  Storable::AMF0 is currently is alpha development stage. 

=cut
=head1 NOTICE

  Storable::AMF0 is currently at alpha development stage. 
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
