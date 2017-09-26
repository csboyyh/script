#! /usr/bin/perl  
##############################################################################
#
#   File          : boardcompare.pl
#   Author(s)     : xiaotong.lu <enck@spreadtrum.com>
#   Description   : compare diffpack/new and diffpack/old,when find same file,
#										compare the two file content, when find different content,
#										insert the differen content in the old file to the new file.
#                   
#
#   Copyright (c) 2017 xiaotong.lu
#
###############################################################################
use strict;
use warnings;
use File::Copy;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::Path qw(make_path remove_tree);
our %params = ();
&getParams();
die "lack params error/n" if(!exists($params{"dir"}) || !exists($params{"old"})|| !exists($params{"new"}));

my $SYSTEM;
my $separator;
my $file;
my @DIRS;
my $flag_replace=0;
my $dirold ="old";
my $dirnew ="new";
#get System Type
if ( $^O =~ /MSWin32/ ) 
{
    $SYSTEM = "NT";
    $separator = "//";
 #   print "Windows NT\n";  
} 
else 
{
    $SYSTEM = "LINUX";
    $separator = "/";
  #  print "LINUX\n";
}
my $dir = $params{"dir"};
my $strold = $params{"old"};
my $strnew =  $params{"new"};
#&boardcopy()
my $stroldupper = $strold;
my $strnewupper = $strnew;
$stroldupper =~  tr/a-z/A-Z/;
$strnewupper =~  tr/a-z/A-Z/;
print "$strnewupper";

my $strnew_ = $strnew;
my $strold_ = $strold; 

$strnew_ =~ tr/_/-/;
$strold_ =~ tr/_/-/;
push(@DIRS,$dir);
&boardcompare();


sub boardcopy()
{
	  if(!(-e $dirnew)){
        mkdir $dirnew or die "cann't open $dir!\n";        
    }
		dircopy($dir,$dirnew); 
		print  "boardcopy\n";
}


sub newlineinsert()
{
	     		        my ($curfile) =  @_;
				open(FILEHANDLE,"+<".$curfile) or die " 2 cann't open $curfile!\n";
				open(FILETEMP,">>Ftemp.txt") or die " 2 cann't open Ftemp!\n";
				my $lines=0;
				my $line;
				my $linetemp;
				my $counter = 1;  	           
				my @ToProcess = <FILEHANDLE>;  
				my  @TEMP = <FILETEMP>;
		
				foreach $line(@ToProcess)
				{
					    #chomp $line;
				   $linetemp = $line;
				   #if($line=~ /$strold/ && $counter==1){
				   #	$flag_replace = 1;
				   #	last;
				   #}
				
				   if($counter >1){
					        #print " counter :$counter\n";
					        $counter--;
				   }elsif($linetemp=~ /$strnew.*_config\s*:\s*preconfig/){
					        $linetemp=~ s/$strnew/$strold/g;
					         print  "files: $line\n";
					         print FILETEMP $linetemp;
					         $counter =1;	
						 while(($ToProcess[$lines+$counter] !~ /^\s*$/)&&($ToProcess[$lines+$counter] !~ /.+_config\s*:\s*preconfig/))
						{
							$_ = $ToProcess[$lines+$counter];
							s/$strnew/$strold/g;
							print FILETEMP $_;
							$counter++;
						}
					        print "preconfig end\n";
					        if($ToProcess[$lines+$counter] =~ /^\s*$/)
					        {
					        		print FILETEMP "\n";
					         }
				   
				   }elsif($linetemp=~ /!defined\(CONFIG_TARGET_.*$strnewupper\)/){
                                        $linetemp=~ s/!defined\(CONFIG_TARGET_SP$strnewupper\)/!defined\(CONFIG_TARGET_SP$stroldupper\) \&\& !defined\(CONFIG_TARGET_SP$strnewupper\)/;
                                        $ToProcess[$lines] =  $linetemp;
                                        print "$linetemp";

                                   }elsif($linetemp=~ /defined\(CONFIG_TARGET_.*$strnewupper\)/){
				   	$linetemp=~ s/defined\(CONFIG_TARGET_SP$strnewupper\)/defined\(CONFIG_TARGET_SP$stroldupper\) \|\| defined\(CONFIG_TARGET_SP$strnewupper\)/;
				   	$ToProcess[$lines] =  $linetemp;
				   	print "$linetemp";				   	
				   	
				   }elsif($linetemp=~ s/TARGET_SP$strnewupper/TARGET_SP$stroldupper/g){				   	
						print  ">>>>upper files: $linetemp\n";
					#	$linetemp=~ s/$strnew/$strold/g;
						print FILETEMP $linetemp;
						$counter=1;
						$linetemp = $ToProcess[$lines+$counter]; 
						while(($linetemp !~ /endchoice/) && ($linetemp !~ /^\s*$/) && ($linetemp !~ /config\s*TARGET_SP.+/))
						{
							$_ = $linetemp;
							s/$strnew/$strold/g;
							print "$_";
							print FILETEMP $_;
							$counter++;
							#if($ToProcess[$lines+$counter] !~ /^\s*$/)
							#{
							#    last;
							#}
							$linetemp =  $ToProcess[$lines+$counter];
						}
						print "Kconfig end\n";
					#	if(($linetemp =~ /endchoice/)||($linetemp =~ /^\s*$/)||($linetemp =~ /config\s*TARGET_SP.+/))
                                                {  
						 	print FILETEMP "\n" ;
						}
								
				   }
				   elsif($linetemp=~ s/MACH_SP$strnewupper/MACH_SP$stroldupper/g){                           
                                                print  ">>>>upper files: $linetemp\n";
                                        #       $linetemp=~ s/$strnew/$strold/g;
                                                print FILETEMP $linetemp;
                                                $counter=1;
                                                $linetemp = $ToProcess[$lines+$counter];
                                                while(($linetemp !~ /^\s*$/) && ($linetemp !~ /config\s*MACH_SP.+/))
                                                {
                                                        $_ = $linetemp;
                                                        s/$strnew/$strold/g;
                                                        print "$_";
                                                        print FILETEMP $_;
                                                        $counter++;
                                                        #if($ToProcess[$lines+$counter] !~ /^\s*$/)
                                                        #{
                                                        #    last;
                                                        #}
                                                        $linetemp =  $ToProcess[$lines+$counter];
                                                }
                                                print "Kconfig end\n";
                                                print FILETEMP "\n" ;

                                   }
				   elsif($linetemp=~ s/$strnewupper/$stroldupper/g)
				   {
					$linetemp=~ s/$strnew/$strold/g;
					print FILETEMP $linetemp;
				   }
				   elsif(($linetemp=~ s/$strnew/$strold/g)||($linetemp=~ s/$strnew_/$strold_/g))
				   {
				      if(($linetemp=~ /dtb/) && ($linetemp!~ /\\/))
				      {
					 print ">>>> dtb\n";
					 chop($linetemp);
					 $linetemp = $linetemp." \\\n";
				      }
				       print FILETEMP $linetemp;
				   }
				   print FILETEMP $line;
				   $lines++;
				}

				close(FILEHANDLE);
				close(FILETEMP);      
				if($flag_replace==0){
						fcopy ("Ftemp.txt" , $curfile);
				}
				unlink "Ftemp.txt";

}

sub boardcompare()
{
    my $dir = pop(@DIRS);
    opendir(DIRHANDLE,$dir) or die "cann't open $dir!\n";
  
     while($file = readdir DIRHANDLE) 
    {
        my $curfile = $dir.$separator.$file; #absolute path
       if (-d $curfile) 
        {
            push(@DIRS, $curfile)  if(($file ne ".") && ($file ne ".."));
        }
	else
        { 
		my  $filenew= $dir.$separator.$file;							
		$_ =  $filenew; 
                s/new/old/;
		$filenew = $_;
		if(-e $filenew)
               {
	    		print  "files: $filenew \n";
			&newlineinsert($curfile);
							}  
        }
    }
    closedir(DIRHANDLE);
    &boardcompare() if(@DIRS >0);
}

sub getParams()
{
   foreach(@ARGV)
   {
      chomp;
      my @sparams = split("=");
      $params{$sparams[0]}=$sparams[1];
   }
}
