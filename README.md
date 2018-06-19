# add-homograph
Perl script which adds homographs to SFM as needed and removes any homographs matching the default value (100) if lexeme is unique.
Using the -u option adds homographs to unique lexemes as well. Default value of homograph for unique lexemes is 100. 

Usage:
  >perl add_hm.pl (default - adds homographs as needed and also removes homograph numbers from lexemes that are unique and match a default value which is typically out of range of most dictionaries.) 
  
  
  >perl add_hm.pl -u (adds homographs as needed plus adds default value homograph to lexemes even though they are unique) 
  
  Requires:
  perl (at least 5.10)
  use utf8;
  
  
