# add-homograph
Perl script which adds homographs to SFM as needed and removes any homographs matching the default value (100) if lexeme is unique.
Using the -u option adds homographs to unique lexemes as well. Default value of homograph for unique lexemes is 100. 


	perl add_hm.pl FILENAME.SFM 

#adds homographs where necessary and removes \hm Default Value (set to 100) from unique entries.
creates timestamp.log in current directory
	 
	perl add_hm.pl FILENAME.SFM -u

#-u opton adds homographs where necessary and adds \hm Default Value (set to 100) to unique #entries.  
#Creates timestamp.log in current directory
#
	
#input file is an SFM file.  This file will be opl'd, processed and de_opl'd. 
#output file is an SFM file.
#
  
  Requires:
  perl (at least 5.10)
  use utf8;
  use oplStuff.pm 
  
  
