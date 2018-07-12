# add-homograph
Perl script which adds homographs to SFM as needed. 
Using the -u option, add_hm.pl will add a default \hm 100 to a unique record as well as adding homographs to non unique entries.

Executing add_hm.pl to an SFM file that includes the default \hm 100 to unique entries will result in the default \hm 100 being removed.


	perl add_hm.pl FILENAME.SFM 

adds homographs where necessary and removes \hm Default Value (set to 100) from unique entries.
Creates timestamp.log in current directory
	 
	perl add_hm.pl FILENAME.SFM -u

-u option adds homographs where necessary and adds \hm Default Value (set to 100) to unique entries.  
Creates timestamp.log in current directory


Assumptions: 	

Input file is an SFM file in utf-8.  
Output file is an SFM file in utf-8.

  
  Requires:
  perl 5.22
  use oplStuff.pm 
  
 oplStuff.pm is included in this project.
  
