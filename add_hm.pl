=comment

Usage:
Edit this file to add infile, outfile, and logfile names.
Example:
my $infile = 'test.opl';
my $outfile= 'testout.db';
my $log_file= 'testlog.txt';

To execute: 
Windows: Double click on this script from Windows Explorer -or- open a cmd prompt, navigate
to the same location as this script, type in 'perl add_hm.pl' without the single quote

Unix: from the command prompt type in 'perl add_hm.pl' without the single quote

=cut

use utf8;
use feature ':5.24';
#use Data::Dumper qw(Dumper);


#update these files:
my $infile = 'Samo5.opl';
my $outfile= 'Samo5oplhm.out';
my $log_file= 'Samo5opl.log';

my $scriptname = $0;

my $row;
my @file_Array;
my %lx_Array;
my $hWord;
my $hm;
my $hWord_hm;
my $lxRow;
my @tmpRec;
my $TO_PRINT = "TRUE";
my $DUPLICATE = "FALSE";
my $ADD_HM_TO_UNIQUE = "FALSE";
my $DEFAULT_HM = 100;
my $numargs = $#ARGV + 1;

open(my $fhlogfile, '>:encoding(UTF-8)', $log_file) 
	or die "Could not open file '$log_file' $!";

open(my $fhoutfile, '>:encoding(UTF-8)', $outfile) 
	or die "Could not open file '$outfile' $!";

open(my $fhinfile, '<:encoding(UTF-8)', $infile)
  or die "Could not open file '$infile' $!";

sub write_to_log{

        my ($message) = @_;
	        print $fhlogfile "$message\n";
}

sub update_homographs{

#I've built my hash array of lexeme->[0|hm+].   Iterate through each of the hm lists and 
#fill in the zero's with the next largest number if the record is a homonym.
#
	foreach my $key ( keys %lx_Array ){
	my %seen;
	my $hm_val;
	my @dup_rec;

		$DUPLICATE = "FALSE";
		@tmpRec = @{$lx_Array{$key}{index}};
		if ( scalar @tmpRec > 1 ){
			#this is a homonym
			#check here to see if we have any duplicate \hm for this lexeme.
	 		@dup_rec = @tmpRec;
			@dup_rec = grep { $_  != 0 } @dup_rec;
			foreach $hm_val (@dup_rec){
				next unless $seen{$hm_val}++;
				$DUPLICATE = "TRUE";
		
			}
			if ($DUPLICATE eq "TRUE"){
				write_to_log(qq(CANNOT PROCEED: Duplicate homograph value for lexeme $key));
				$TO_PRINT = "FALSE";
	 		}	
			else {
				for (my $i=0; $i< scalar @tmpRec; $i++ ){
					if ( $tmpRec[$i] == 0 ){
						#get max number 
						my @sorted = sort { $a <=> $b } @tmpRec;
						my $largest = pop @sorted;
						$largest++;
						@tmpRec[$i]=$largest;
						write_to_log("Updating lexeme $key with hm $largest");
					}
				}
			}
		}


	@{$lx_Array{$key}{index}} = @tmpRec;

	}
}


 
write_to_log("Input file $infile Output file $outfile");
if ( $numargs == 1 ){
	if (@ARGV[0] eq "-u"){ $ADD_HM_TO_UNIQUE = "TRUE"; write_to_log(qq(ADD_HM_TO_UNIQUE set to TRUE)); }
	else { die "Usage: [add_hm.pl|add_hm.pl -u]"; }
}


#1st pass - build lx_Array, a hash lexeme->[hm,hm,hm] or lexeme->[0] if it is not a homonym.
#Read the file into memory file_Array;

while ( <$fhinfile> ) {

	if (/\\lx (.*?)#\\hm (.d*?)/){
		push @{$lx_Array{$1}{index}}, $2;
	}
	elsif (/\\lx (.*?)#/){
		push @{$lx_Array{$1}{index}}, 0;
	}
	push @file_Array, $_;

}


#print Dumper(\%lx_Array);



update_homographs();

#print Dumper(\%lx_Array);



if ($TO_PRINT eq "TRUE"){

	foreach my $r (@file_Array){

		if ($r =~ /^\\lx (.*?)#\\hm (.*?)#/){ 
			if ( $2 == $DEFAULT_HM ){
				$r =~ s/^(\\lx [^#]*#)\\hm (.*?)#/$1/;
			}
		}
		elsif( $r =~ /^\\lx (.*?)#/ ){
			my $hm = shift @{$lx_Array{$1}{index}};
			if ( $hm > 0 ){ 
				$r =~ s/^(\\lx [^#]*#)/$1\\hm $hm#/;
			}
			if ( $ADD_HM_TO_UNIQUE eq "TRUE" ){
				write_to_log(qq(Adding \\hm $DEFAULT_HM to unique lexeme $1));
				 
				if ( $hm == 0 ){
					$r =~ s/^(\\lx [^#]*#)/$1\\hm $DEFAULT_HM#/;
				}
			}
		}
		print $fhoutfile $r;
	}
}
else {
	write_to_log (qq(Duplicate \\hm values have been found. SFM file must be corrected.));
	print $fhoutfile (qq(No data has been written. See details in log file.))

}



close $fhlogfile;
close $fhinfile;
close $fhoutfile;

