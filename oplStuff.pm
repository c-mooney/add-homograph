package oplStuff;
use strict;
use warnings;
use Exporter;


our @ISA = qw( Exporter );
our @EXPORT = qw ( opl_file de_opl_file );

sub opl_file{

my $infile  = $_[0];
my @tmp;



open(my $fhinfile, '<:encoding(UTF-8)', $infile)
  or die "Could not open file '$infile' $!";


	my $FIRST_LINE = 1;
	my $line;
	while (<$fhinfile>){
		if ( $^O =~ /linux/ ){
			s/\r\n/\n/g;
		}
		chomp;
		if ( $FIRST_LINE == 1 ){
			$FIRST_LINE = 0;
		}
		elsif (/\\lx / ){

			push @tmp, $line; 
			#push @tmp, $line."\n"; 
			$line="";
				
		}
		s/#/\_\_hash\_\_/g;
		$line .= $_."#";		
	}
	$line .= "#";		
	push @tmp, $line."\n";
close $fhinfile;
return @tmp;
}


sub de_opl_file{
	#added wrapper "if" because I get a warming if I don't.
	if ( length $_[0] ){
		my $l = $_[0];
		#chomp $l;
		$l =~ s/#/\n/g;
		$l =~ s/\_\_hash\_\_/#/g;
		return $l;
	}
	else { return 0; }
}

