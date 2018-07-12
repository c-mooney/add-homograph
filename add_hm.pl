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

#########  ASSUMPTIONS  ###############

\hm value is a digit.  

=cut

use utf8;
use feature ':5.22';
use strict;
use warnings;
use Data::Dumper qw(Dumper);
use Time::Piece;
use oplStuff;

my $date = Time::Piece->new;
$date->time_separator("");
$date->date_separator("");
my $tm = $date->datetime;

my $infile ="";
my $scriptname = $0;
my $logfile = "$tm.log";
my %hm_collection_hash;
my %scalar_count;
my @dups;
my @tmpRec;
my $DUPLICATE = 0;
my $ADD_HM_TO_UNIQUE = 0;
my $DEFAULT_HM = 100;
my $numargs = $#ARGV + 1;


if ( $numargs == 0 ){
	 die "Usage: perl add_hm.pl FILENAME [-u]"; 
}
elsif ( $numargs == 1 ){
	$infile = $ARGV[0]; 
}
else {
	$infile = $ARGV[0]; 
	if ($ARGV[1] eq "-u"){ $ADD_HM_TO_UNIQUE = 1; }
	else { die "Usage: perl add_hm.pl FILENAME [-u]"; }
}


open(my $fhlogfile, '>:encoding(UTF-8)', $logfile) 
	or die "Could not open file '$logfile' $!";

 
write_to_log("Input file $infile");

#opl the file - i.e. put each record on a line.
my @opld_file = opl_file($infile);

#Build hm_collection_hash, a hash with the lexeme as the key; lexeme->[hm,hm,hm] or lexeme->[0] if it is not a homonym.  
#If hm does not exist in the record, but the lexeme is not unique, add a 0 to the array 
#as a place holder to be filled in later with a proper homograph number.
#Array may look something like:
#   A->[3,2]    Found lexeme A with homographs 3, 2.  
#   B->[0]      Lexeme B is unique - not a homograph.
#   C->[0,0,0]  Lexeme C is found 3 times, but no homograph numbers.  
#   D->[1,0,0]  Lexeme D is found 3 times, the first entry found has \hm 1.

foreach my $line (@opld_file) {
my $hm;
my $key;

	if ($line =~ /\\lx (.*?)#((.*?)\\hm (\d*?)#)*/){
		$hm = $2 ? $4 : 0;
		$key = $1;
        	push @{$hm_collection_hash{$key}}, $hm;

		#verify a non zero hm value is a duplicate.  If it is, write the info to the logfile. 
		#no processing will be done on a file that contains duplicate hm numbers.

		if ( (scalar @{$hm_collection_hash{$key}} > 1 ) && ( $hm > 0) ){
			#test for duplicate homograph numbers
			@dups =  grep { $hm == $_ } @{$hm_collection_hash{$key}} ;
			if ( scalar @dups > 1 ){
				$DUPLICATE = 1;
				write_to_log("CANNOT PROCEED: Duplicate homograph value for lexeme $key");
			}	
		}

	}

}


#Add the homographs where I've found a non unique lexeme.
update_homographs();


#If no duplicate homographs were found, we can write the updated file
if ($DUPLICATE == 0){

	if ( $ADD_HM_TO_UNIQUE == 1 ){
		write_to_log("\nAdding default value $DEFAULT_HM to unique lexemes\n");
	}
	foreach my $r (@opld_file){
		if ($r =~ /(\\lx (.*?)#.*\\hm (\d*?)#)/){ 
			if ( $3 == $DEFAULT_HM ){
				if ( $scalar_count{$2} > 1 ) {
					$r =~ s/^(\\lx [^#]*#)\\hm (.*?)#/$1\\hm 1#/;
				}
				elsif ( $ADD_HM_TO_UNIQUE == 0 ){
					$r =~ s/^(\\lx [^#]*#)\\hm (.*?)#/$1/;
				}
			}
		}
		elsif ( $r =~ /^\\lx (.*?)#/ ){ 
			my $hm = shift @{$hm_collection_hash{$1}};
			if ( $hm > 0 ){ 
				$r =~ s/^(\\lx (.*?#))/$1\\hm $hm#/;
			}
			elsif ( $ADD_HM_TO_UNIQUE == 1 ){
				write_to_log("Adding \\hm $DEFAULT_HM to unique lexeme $1");
				$r =~ s/^(\\lx [^#]*#)/$1\\hm $DEFAULT_HM#/;
			}
		}
		
		#print out the file 
		print de_opl_file($r); 

	}
}
else {
	write_to_log ("Duplicate \\hm values have been found. SFM file must be corrected.");
	print ("Duplicate homograph numbers found.  No data has been written. See details in log file.\n");

}

close $fhlogfile;
######################  SUBROUTINES #################################

sub update_homographs{

#I've built my hash array of lexeme->[0|hm+] (hm_collection_hash).   Iterate through each of the hm lists and 
#fill in the zeros with the next largest number if the record is a homonym.
#
#Use hm_collection_hash to create a scalar_count.  scalar_count key = lexeme, value = # of homographs.  This is used
#later in determining which lexeme was an "original" entry after new entries have been added (presumably by se2lx).
#
my $key;
	foreach  $key ( keys %hm_collection_hash ){

		@tmpRec = @{$hm_collection_hash{$key}};
		$scalar_count{$key} = scalar @tmpRec;

		#special processing needed here in the case add_hm has added the 
		#default hm number to a unique lexeme, but after further processing, 
		#I now find that the lexeme is no longer unique.  
		#In this case, set the default value to 1.
		if ( $ADD_HM_TO_UNIQUE == 0 ){
			for (my $i=0; $i< scalar @tmpRec; $i++){
				if ( $tmpRec[$i] == $DEFAULT_HM ){
					$tmpRec[$i] = 1;

				}
			}

		}
		#iterate through the list of hm numbers.  Replace zeros with the next 
		#highest value.
		if ( scalar @tmpRec > 1){
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

		@{$hm_collection_hash{$key}} = @tmpRec;

	}
}
sub write_to_log{

        my ($message) = @_;
                print $fhlogfile "$message\n";
}
