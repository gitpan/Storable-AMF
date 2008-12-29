package GrianUtils;
use strict;
use warnings;
use Storable::AMF qw() ;
use Carp qw/carp croak/;
use Fcntl qw(:flock);
use File::Spec;
use Scalar::Util qw(refaddr reftype);
use base 'Exporter';

our (@EXPORT, @EXPORT_OK);
@EXPORT_OK=qw(ref_mem_safe);

sub hash_contain_only{
	my $self = shift;
	my $hash = shift;
	my $hash_compare = shift;
	! exists $hash_compare->{$_} && return 0 foreach keys %$hash;
	return 1;
}
	
sub pg_encode_slow{
	my $class = shift;
	my $s = shift;
	#~ $s =~ s/([\377\000])/"\377".unpack("H*",$1)/gse;
	our %pg_encode;
	$s=~s/([\000\377\376])/$pg_encode{$1}/gs;	
	return $s;
}
sub pg_decode_slow{
	my $class = shift;
	my $s = shift;
	our %pg_decode;
	$s =~s/([\376]|(?:\377.))/$pg_decode{$1}/gs;
	#~ $s =~s/\377(..)/pack("H*", $1)/gse;
	return $s;
}
sub hex_encode{
	my $class = shift;
	my $s     = shift;
	return unpack "H*", $s;
}

sub hex_decode{
	my $class = shift;
	my $s     = shift;
	return pack "H*", $s;
}

sub pg_encode{
#	return XS::Pg::pg_encode($_[1]);
}

sub pg_decode{
#	return XS::Pg::pg_decode($_[1]);
}
sub pg_freeze{
	my $class  = shift;
	my $object = shift;
	my $encode    = shift || 'AMF';
	carp "undefined object" unless defined $object;
	if ($encode eq 'Storable') {
		return $class->pg_encode(Storable::freeze $object);
	}
	elsif ($encode eq 'AMF') {
		return Storable::AMF::freeze $object;
	}
	else {
		carp "Unknown encoding at pg_thaw";
	}
}

sub pg_thaw{
	my $class  = shift;
	my $pg_string = shift;
	my $encode    = shift || 'AMF';
	carp "undefined pg_string" unless defined $pg_string;
	if ($encode eq 'Storable') {
		return eval {Storable::thaw $class->pg_decode($pg_string) };
	}
	elsif ($encode eq 'AMF') {
		return Storable::AMF::thaw $pg_string;
	}
	else {
		carp "Unknown encoding at pg_thaw";
	}
}

sub my_readdir{
	my $class = shift;
    my $dirname = shift;
	my $option  = shift || 'abs';
	opendir my $SP, $dirname
	  or die "Can't opendir $dirname for reading";
	if ($option eq 'abs') {
		return  map {File::Spec->catfile($dirname, $_)} grep { $_ !~ m/^\.\.?$/ } readdir $SP;
	}
	elsif( $option eq 'rel' ) {
		return map {$dirname ."/". $_}  grep { $_ !~ m/^\./ } readdir $SP;
	}
	else {
		carp "unknown option: $option. Available options are 'abs' or 'rel'";
		return ();
	}
}
sub my_readfile{
	my $class = shift;
    my $file = shift;
	my $buf;
	open my $filefh, "<", $file
	or die "Can't open file '$file' for reading";
	flock $filefh, LOCK_SH;
	read $filefh, $buf,  -s $filefh;
	flock $filefh, LOCK_UN;
	close ($filefh);
	return $buf;
}

sub abs2rel{
	my $class    = shift;
	my $abs_path = shift;
	my $base     = shift;
	$base=~s/[\\\/]$//;
	$base=~s/\\/\//g;
	$abs_path=~s/\\/\//g;
	if ($base eq '.'){
		$base=~s/^\.//g;
		$abs_path=~s/^\.\///g;
		return "./$abs_path";
	}
	print STDERR "path='$abs_path' base='$base'\n";
	carp "Path can't transformed to relative: path='$abs_path' base='$base'" unless substr($abs_path, 0, length($base)) eq $base;	
	return ".".substr($abs_path, length($base));
}

# not tested yet
sub rel2abs{
	my $class    = shift;
	my $rel_path = shift;
	my $base     = shift;
	$base=~s/[\\\/]$//;
	$rel_path=~s/^\.\///;	
	carp "Path isn't relative: path='$rel_path' base='$base'" if $rel_path=~/^[\\\/]/;	
	return File::Spec->catfile($base, $rel_path);
}

sub _all_refs_addr{
    my $c = shift;
    while(@_){
        my $item = shift;
        
        next unless refaddr $item;
        next if $$c{refaddr $item};
        #print refaddr $item, "\n";
        $$c{refaddr $item} = 1;
        if (reftype $item eq 'ARRAY'){
            _all_refs_addr($c, @$item);

#~             foreach (_all_refs_addr($c, @$item)){
#~                 $$c{$_} = 1;
#~             }
        }
        elsif (reftype $item eq 'HASH') {
            _all_refs_addr($c, $_);
            #@$c{map {_all_refs_addr($c, $_)} values %$item} = ();
        }
        elsif (reftype $item eq 'SCALAR') {            
        }
        elsif (reftype $item eq 'REF'){
            _all_refs_addr($c, $$item)
            #$$c{_all_refs_addr($c, $$item)} = 1;
        }
        else {
            croak "Unsupported type ". reftype $item;
        }
    }
    return keys %$c;
}
       use List::Util qw(max); 
sub ref_mem_safe{
    my $sub = shift;
    my $count_to_execute = shift ||200;
    my $count_to_be_ok   = shift ||50;
    
    my $nu = -1;
    my @addresses;
    my %addr;
    my $old_max =0;
    for my $round (1..$count_to_execute){
        my @seq = &$sub();
        #my $a   = {};
        push @seq,(\my $b), [], {}, &$sub(),[],{},\my $a;
        my $new_max = max ( _all_refs_addr( {}, @seq ,$a, ));
            if ($old_max<$new_max){
                $old_max = $new_max;
                $nu = -1;
            };
#~             unless (grep {$_ == $addr} @addresses){
#~                 push @addresses, $addr;
#~                 $nu = -1;
#~             };
        ++$nu;
        return $round if ($nu > $count_to_be_ok) ;
    }
    return 0;
}
1;
