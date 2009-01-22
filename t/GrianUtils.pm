package GrianUtils;
use strict;
use warnings;
use Storable::AMF qw() ;
use Carp qw/carp croak/;
use Fcntl qw(:flock);
use File::Spec;
use Scalar::Util qw(refaddr reftype);
use List::Util qw(max); 
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
    my @dirs = @_;
	my $buf;
    $file = File::Spec->catfile(@_, $file);
	open my $filefh, "<", $file
	or die "Can't open file '$file' for reading";
	flock $filefh, LOCK_SH;
	read $filefh, $buf,  -s $filefh;
	flock $filefh, LOCK_UN;
	close ($filefh);
	return $buf;
}

sub create_pack{
    my $class = shift;
    my $name  = shift;
    my $dir   = shift;



}
sub list_content{
    my $class = shift;
    my $dir   = shift;
    my $regex = shift || qr//;
    my $folder = $class->content($dir);
    return () unless $folder;
    return grep { $_=~ $regex } keys %$folder;
};

our $pack = "(w/a)*";
our @fixed_names = qw(eval amf0 amf3);
sub _pack{
    my $hash = shift;
    my (@fixed) = delete @$hash{@fixed_names};
    #my $s = \ pack "N/aN/aN/a(N/aN/a)*", $eval, $amf0, $amf3, %$hash;    
    my $s = \ pack $pack, @fixed, %$hash;    
    @$hash{@fixed_names} = (@fixed);
    return $$s;
}
use Storable::AMF0;
use Data::Dumper;
sub _unpack{
    my (@fixed, %rest);
    (@fixed[0..$#fixed_names], %rest) = unpack $pack, $_[0];
    @rest{@fixed_names} = (@fixed);
    return \%rest;    
};

sub read_pack{
    my $class = shift;
    my $dir   = shift;
    my $name  = shift;
    my $folder = $class->content($dir);
    return  $$folder{$name};
    print Dumper($$folder{$name}, _unpack(_pack($$folder{$name})));

}

our %dir;
sub content{
    my $class = shift;
    my $dir   = shift;

    return $dir{$dir} if $dir{$dir};
    my @content = grep {-f $_ and -r $_ } grep { $_!~m/(?:^|(?:[\\\/]))\.{1,2}/ } $class->my_readdir($dir);
    my %folder;
   
    my @name = grep { m/(?:amf0|pack)$/ } @content;
    
    for (@name){
        $_=~s/\.(?:amf0|pack)$//;
        m/(.*[\/\\])/; # basename
        my $pos = $+[0];
        my $sname = substr($_, $pos);
        my $name = substr($_,0, $pos+length($sname));
        my $ext;
        my @c = grep { m/\Q$name.\E\w{2,}+$/ } @content;
        no warnings;

        for (@c){
            $ext = substr $_, ($pos + length($sname)+1);
            my $f_content = $class->my_readfile($_);
            $folder{$sname}{$ext}=$f_content; 
        };
        if (! exists $folder{$sname}{'pack'} ){
            my $pack_name = $_.".pack";
            delete $folder{$sname}{'pack'};

            open my $fh, ">", $pack_name or die "can't open $pack_name";
            binmode($fh);
            print $fh _pack($folder{$sname});
            close($fh);            
        }
        else {
            my $packet  = $folder{$sname}{'pack'};
            $folder{$sname} = _unpack($packet);
            delete $folder{$sname}{'pack'};
        }
    };
    $dir{$dir} = \%folder;
    return \%folder;
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
        }
        elsif (reftype $item eq 'HASH') {
            _all_refs_addr($c, $_);
        }
        elsif (reftype $item eq 'SCALAR') {            
        }
        elsif (reftype $item eq 'REF'){
            _all_refs_addr($c, $$item)
        }
        else {
            croak "Unsupported type ". reftype $item;
        }
    }
    return keys %$c;
}
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
        ++$nu;
        return $round if ($nu > $count_to_be_ok) ;
    }
    return 0;
}
1;
