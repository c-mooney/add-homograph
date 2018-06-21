=comment

Usage:
#adds homographs where necessary and removes \hm Default Value (set to 100) to unique entries.
#hm Default Value is placed in an SFM when using this script with the -u option. Creates log file add_hm.<time>.log
#
	perl add_hm.pl FILENAME.SFM  


#adds homographs where necessary and adds \hm Default Value (set to 100) to unique entries.  
#Creates log file add_hm_u.<time>.log
#
	perl add_hm.pl FILENAME.SFM -u


#input file is an SFM file.  This file will be opl'd, processed and de_opl'd. 
#output file is an SFM file.
#
=cut

use utf8;
use feature ':5.24';
use strict;
use warnings;
use Data::Dumper qw(Dumper);
use Time::Piece;
my $date = Time::Piece->new;
$date->time_separator("");
$date->date_separator("");
my $tm = $date->datetime;

my $infile ="";
my $scriptname = $0;
my $logfile = "$tm.log";
my %lx_Array;
my $hm;
my @tmpRec;
my $TO_PRINT = "TRUE";    #Flag indicates 
my $DUPLICATE = "FALSE";
my $ADD_HM_TO_UNIQUE = "FALSE";
my $DEFAULT_HM = 100;
my $numargs = $#ARGV + 1;
my @opld_file;

$tm = $date->strftime();
if ( $numargs == 0 ){
	 die "Usage: [add_hm.pl FILENAME | add_hm.pl FILENAME -u]"; 
}
elsif ( $numargs == 1 ){
	$infile = $ARGV[0]; 
}
else {
	$infile = $ARGV[0]; 
	if ($ARGV[1] eq "-u"){ $ADD_HM_TO_UNIQUE = "TRUE"; }
	else { die "Usage: [add_hm.pl FILENAME | add_hm.pl FILENAME -u]"; }
}


open(my $fhlogfile, '>:encoding(UTF-8)', $logfile) 
	or die "Could not open file '$logfile' $!";

open(my $fhinfile, '<:encoding(UTF-8)', $infile)
  or die "Could not open file '$infile' $!";

 
write_to_log("$tm\n$scriptname Input file $infile");

#1st opl the file - i.e. put each record on a line.

opl_file();
#print opl_file;
	

close $fhinfile;

#2nd build lx_Array, a hash lexeme->[hm,hm,hm] or lexeme->[0] if it is not a homonym.  If hm does not exist in the record, but the lexeme 
#is not unique, add a 0 to the array as a place holder to be filled in later with a proper homograph.


foreach my $line (@opld_file) {

	if ($line =~ /\\lx (.*?)#\\hm (.d*?)/){
		push @{$lx_Array{$1}{index}}, $2;
	}
	elsif ($line =~ /\\lx (.*?)#/){
		push @{$lx_Array{$1}{index}}, 0;
	}

}


#3rd add the homographs where I've found a non unique lexeme.
update_homographs();

#print Dumper \%lx_Array;



#if no duplicate homographs were found, then we can print out the updated file
if ($TO_PRINT eq "TRUE"){

	if ( $ADD_HM_TO_UNIQUE eq "TRUE" ){
		write_to_log("\nAdding default value $DEFAULT_HM to unique lexemes\n");
	}
	foreach my $r (@opld_file){
		if ($r =~ /\\lx (.*?)#\\hm (\d*?)#/){ 
			if ( $2 == $DEFAULT_HM ){
				$r =~ s/^(\\lx [^#]*#)\\hm (.*?)#/$1/;
			}
	
		}
		elsif ( $r =~ /^\\lx ([^#]*)#/ ){ 
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
		
		print de_opl_file($r); 

	}
}
else {
	write_to_log (qq(Duplicate \\hm values have been found. SFM file must be corrected.));
	print (qq(No data has been written. See details in log file.));

}




close $fhlogfile;

######################  SUBROUTINES #################################

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

sub opl_file{
	my $firstLine = "TRUE";
	my $line;
	while (<$fhinfile>){
		chomp;
		if (/\\lx /){
			push @opld_file, $line."\n"; 
			$line="";
		}
		s/#/\_\_hash\_\_/g;
						#$_ .= "#";
		$line .= $_."#";		
						#push @opld_file, $_;
	}
	$line .= "#";		
	push @opld_file, $line."\n";
}


sub de_opl_file{

	if ( length $_[0] ){
		my $l = $_[0];
		chomp $l;
		$l =~ s/#/\n/g;
		$l =~ s/\_\_hash\_\_/#/g;
		return $l;
	}
	else { return ""; }
}

