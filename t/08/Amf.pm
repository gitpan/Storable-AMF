use Storable::AMF qw(thaw freeze); 
use IO::Handle;
use IO::Socket::INET;
use Time::HiRes qw(sleep);
use Test::More no_plan=>1;
my  $socket= new IO::Socket::INET (
		Listen		=> '10',
		LocalPort	=> '9998',
		ReuseAddr	=> 1,
) or die "can't open socket";

print unpack "H*", "asdf";
print "\n";
print decode("\0\1ddf"), "\n";
while( $stream = $socket->accept()){
	my $pid;
	unless ($pid = fork) {
		my ($name, $amf0, $amf3, $eval);
		my ($read_ok);


		$read_ok = 1;
		print STDERR "connect\n";

		my $free = freeze([]);
		print $stream pack('N', length($free)), $free;
		$stream->flush();
		while ($read_ok) {
				#print STDERR "next object\n";
				$read_ok = stream_chunk($stream, $name) if $read_ok;
				$read_ok = stream_chunk($stream, $amf0) if $read_ok;
				$read_ok = stream_chunk($stream, $amf3) if $read_ok;
				$read_ok = stream_chunk($stream, $eval) if $read_ok;
				#ok(defined(thaw $amf0));
				next unless $read_ok;
				is_deeply(thaw($amf0), eval ("do {$eval;} "), "name = $name\neval=$eval ");
				
				print STDERR Data::Dumper->Dump([thaw ($amf0), eval("do { $eval }"), decode($amf0)]) ;



				do {
					write_file("AMF/$name", $eval);
					write_file("AMF/$name.amf0", $amf0);
					write_file("AMF/$name.amf3", $amf3);
				}
				if $read_ok;


			
#~ 				$read = $stream->sysread($buf, 4);
#~ 				last unless $read;
#~ 				$length = unpack "N", $buf;
#~ 				printf "packet length %d, count=%d\n", $length, ++$count;				
#~ 				$buf ='';
#~ 				do {
#~ 					$read = $stream->sysread($buf, $length, length($buf));
#~ 				} ;
		#~ 		if (length $buf){
		#~ 			open my $fh , ">","message";
		#~ 			print $fh $buf;
		#~ 			close($fh);
		#~ 
		#~ 		} else {
		#~ 			open my $fh, "<", "message";
		#~ 			sysread $fh, $buf, 1000;
		#~ 			close($fh);
		#~ 		};
				#printf "Accept %d bytes\n", length $buf;
				#print STDERR Data::Dumper->Dump([unpack "H*",($buf)]);
				printf STDERR "Get chunk %20s %4d %4d %4d\n", $name, map {length } $amf0, $amf3, $eval;
		};
		object:
		close($stream);
		printf "finished reading: Child exit\n";
	}
	else {
		close($stream);
	}
};
sub write_file{
	my $file = shift;
	my $buf  = shift;
	open my $fh, ">", $file or die "Can\'t open $file";
	binmode($fh);
	print $fh $buf;
	close($fh) or die "Can't close $file";
}
sub stream_chunk{
	my $stream = shift;
	my $buf;
	my $read_ok;
	my $length;
	$read_ok = $stream->sysread($buf, 4);
	return $read_ok unless $read_ok ;
	$length = unpack 'N', $buf;
	#print STDERR "length is ", $length, "\n";
	$_[0] = '';
	do {
		$read_ok = $stream->sysread($_[0],  $length - length($_[0]),  length($_[0]));
	}
	while(defined($read_ok) && (length($_[0]) < $length));
	return length($buf) if $read_ok;
	return $read_ok;
}

sub decode{
	my $str = shift;

	my $s =  unpack "H*",  $str;
	$s=~s/(\w{4})/$1 /g;
	return $s;
	scalar join "", map {ord($_) >(31) && ord($_)< 128? $_: "\x".unpack "H*", $_} split '', $str;
};

