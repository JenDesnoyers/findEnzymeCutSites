#This script reads in a FASTA file as well as a file containing enzymes and their cut sites (both files provided as arguments), and then finds the cut sites of the enzymes in the 
#FASTA sequence. The script then produces an output file containing various pieces of information including, but not limited to, file names, header, number of cut sites, fragments
#produced, etc. 


#Use strict and use warnings forces Perl to provide more information on why a script wasn't executed. These warnings are very helpful and can save a lot of troubleshooting time.

use strict;
use warnings;


#The next two lines set the @ARGV array to equal $enzyme_File and $fasta_File. This means that the command line will expect two arguments (the file containing the enzymes and a fasta file, in that order)
#If exactly two files are not provided, die() will cause the script to end and then will print an error message to the screen to tell the user why the script was ended.   

my ($enzyme_File, $fasta_File) = @ARGV;

if (@ARGV != 2) {
	die "Need to provide two files: a file containg enzymes and a fasta file. Also, please provide the enzyme file followed by the fasta file in the command line.\n";
}


#The next few lines open various files for reading ('<' $enzyme_File and $fasta_File) or  writing ('>' $enzyme_Report_File). Die() is used if the files, for whatever reason, cannot be read or written 
#to. An error message is then printed to the screen to let the user know why the script has been ended.

open (my $enzyme, '<', $enzyme_File) or die "Could not open '$enzyme_File' for reading: $!\n";
open (my $fasta, '<', $fasta_File) or die "Could not open '$fasta_File' for reading: $!\n";
open (my $report, '>', 'enzyme_Report_File.txt') or die "Could not open enzyme_Report_File.txt for writing: $!\n";

	
#The next part of the code extracts the header and sequence from the fasta file by taking advantage of the fact that <> can be used to access the first line of a file by using it once, 
#and then the second line of the file by using <> again. Chomp is then used on both $header and $sequence, because without doing so, newline characters will affect printing and length(). 
	
my $header = <$fasta>;
chomp($header);
my $sequence = <$fasta>;
chomp($sequence);
my $seq_Length = length($sequence); 

	
#The following block of code prints various information to the enzyme_Report_File, which is stored in the $report variable. 
	
print $report ("This is a report detailing restriction enzyme cut sites from the $enzyme_File file and their effect on the sequence contained in the $fasta_File file.\n\n");
print $report ("The name of the sequence provided in the fasta file is: $header.\n");
print $report ("The length of the sequence is $seq_Length bases.\n");
print $report ("-" x 200); #This line prints 150 '-' characters, which on a 13 inch screen spans most of the horizontal space.  
print $report ("\n"); #Prints a blank line.
	
#The next part of the code uses a while loop to extract various pieces of information from each enzyme in the provided enzyme file. 
	
while (my $enzyme_Line = <$enzyme>) {


	#The next part of the code extracts the enzyme name and enzyme cut site using the split() function. Split() will remove whatever delimiter is used, in this case the ';', and will
	#allow each element created to be accessed using [#]. 
		
	my @split_Enzymes = split /;/, $enzyme_Line;
	chomp(@split_Enzymes);  
	my $enzyme_Name = $split_Enzymes[0]; #Sets $enzyme_Name equal to the first element in the @split_Enzymes array.
	my $enzyme_CutSite = $split_Enzymes[1]; #Sets $enzyme_CutSite equal to the second element in the @split_Enzymes array.
		

	#The next part of the code extracts the cut site before and after the '^', using the split() function described above, saving them to the variable $enzyme_Front and $enzyme_Back, 
	#respectively. These will be used later to make fragments.
		
	my @split_CutSite = split /\Q^\E/, $enzyme_CutSite; #\Q and \E makes '^' a normal character instead of a metacharacter. Otherwise, the regex will match the front of the string not '^'.
	chomp(@split_CutSite);
	my $enzyme_Front = $split_CutSite[0];
	my $enzyme_Back = $split_CutSite[1];
  

	#The next part of the code removes the '^' so that I can use the enzyme cut site as a pattern when searching the nucleotide sequence from the fasta file.
		
	(my $enzyme_Pattern = $enzyme_CutSite) =~ tr/^//d; #tr would usually replace '^' with something. Because I have //, tr replaces '^' with nothing, leaving just nucleotides.
		

	#The next part of the code uses split() and the $enzyme_Pattern created above to split the fasta sequence into fragments. As mentioned before, split() removes what it uses to split, 
	#in this case the enzyme cut site. This is why I had to save the nucleotides before and after '^', so that I could add them back to the fragments (done below). 
		
	my @seq_Words = split /$enzyme_Pattern/, $sequence;
		
		
	#The next part of the code uses foreach statements nested inside of an if statment in order to add back the nucleotides that were removed by split(). If there is only one
	#element in the @seq_Words array, then there were not any cut sites so there are no fragments, and there is no need to add back the cut sites. However, if there is more than
	#one element, then there is at least one cut site and the fragments have to be modified. $enzyme_Front is added to the end of every fragment except the last, since the enzyme cuts 
	#after that point but I didn't want to add nucleotides that didn't originally exist (by adding $enzyne_Front to the last element in the array). $enzyme_Back is added to the front 
	#of every fragment except the first.
 
	if (scalar @seq_Words > 1) {
		foreach my $i (@seq_Words[0 .. $#seq_Words-1]) { #[0 .. $#seq_Words-1] means that the foreach loop will work on every element in the array except the last one.
                	$i .= $enzyme_Front;
                }

                foreach my $j (@seq_Words[1 .. $#seq_Words]) { #[1 .. $#seq_Words] means that the foreach loop will work on every element in the array except the first one.
                        $j = $enzyme_Back.$j;
                }
	} 


	#The next two variables find the number of cut sites and the number of fragments produced by the current enzyme. The information contained in these variables is printed to the outfile
	#later on.

	my $number_OfCutSites = scalar @seq_Words - 1; 
	my $number_OfFragments = scalar @seq_Words;
		

	#The next block of code is an if/else statement that is used to write various pieces of information (enzyme name, cut site, number of fragments produced, number of cut sites
	#found, and the sequence of the fragments themselves) to the enzyme_Report_File. If the @seq_Words array only contains one element, fragments are not processed because
	#clearly no fragments were produced or there would be more than one element in the array (one cut site produces two fragments, so one element = no cut sites). 
		
	my $fragment_Position = 1;
	if (scalar @seq_Words > 1) {
		print $report ("\n$enzyme_Name cuts at $enzyme_CutSite.\n");
		print $report ("Within the sequence provided there is/are $number_OfCutSites cut site(s), which produces $number_OfFragments fragments:\n");
			

		#The following foreach loop makes the script work with one fragment at a time. This makes formatting the output a lot easier.
			
		foreach my $fragment (@seq_Words) {
			my $fragment_Length = length($fragment);
			print $report ("\nLength of fragment: $fragment_Length\n");
				
			#The if/else statements below are again required to make formatting the output easier. If the fragment ($fragment) from the @seq_Words array is longer than 60
			#nucleotides, then $fragment =~ s/(\w{60})/$1@/g; and my @fragments = split /@/, $fragment; are required to split the fragment into lines no greater than 60 nucleotides long.
			#Aterwards, the fragment will be further processed with another foreach loop acting on the @fragment array to split each line into 6 groups of 10 (unless the fragment
			#doesnt equal 60 then the last group of nucleotides could be any length). However, if the fragment ($fragment) from the @seq_Words array is less than 60 nucleotides, 
			#then the fragment is only processed using $fragment =~ s/(\w{10})/$1 /g; because it doesn't need to be split into lines no greater than 60 nucleotides. Furthermore, 
			#a counter called fragment_Length (initialized above) is used to keep track of the position of the first nucleotide of each fragment on each line. 
  
			if (length($fragment) > 60) {
				$fragment =~ s/(\w{60})/$1@/g; #Inserts a '@' at every 60th character. 
				my @fragments = split /@/, $fragment; #Splits the $fragment string at each @ (which gets rid of the '@' character) which leaves elements that are no longer than 60.
				foreach my $fragment2 (@fragments) {
					my $fragment_Length2 = length($fragment2);
					$fragment2 =~ s/(\w{10})/$1 /g; #Inserts a space after every 10th character. 
					print $report ("$fragment_Position\t$fragment2\n");
					$fragment_Position = $fragment_Position + $fragment_Length2;
				}
			} else {
				$fragment =~ s/(\w{10})/$1 /g;
				print $report ("$fragment_Position\t$fragment\n");
				$fragment_Position = $fragment_Position	+ $fragment_Length;
			}
		}

		print $report ("-" x 200);
        	print $report ("\n");

	} else {
		print $report ("$enzyme_Name produces no fragments.\n");
		print $report ("This must be because the sequence provided does not contain the cut site recognized by $enzyme_Name ($enzyme_CutSite)\n\n");
		print $report ("-" x 200);
        	print $report ("\n");
	} 
}


#The last few lines of code close all files that were opened above. This is good practice. Most of the time not explicitly closing a filehandle isn't a problem. Nevertheless, it's best to just close 
#the filehandle in the script. 

close($enzyme);
close($fasta);
close($report);
