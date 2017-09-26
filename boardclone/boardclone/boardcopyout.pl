#! /usr/bin/perl  
##############################################################################
#
#   File          : boardcopyout.pl
#   Author(s)     : xiaotong.lu <enck@spreadtrum.com>
#   Description   : copy dir to the diffpack/new and copy to the diffpack/old
#										
#										
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
die "lack params error/n" if(!exists($params{"dir"}) || !exists($params{"old"}));

my $SYSTEM;
my $separator;
my $file;
my @DIRS;
#my $dirnew ="diffpack/new/new/new";
#my $dirold ="diffpack";
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
    print "LINUX\n";
}
my $dir = $params{"dir"};
my $dirtemp = $dir;
my $dirtemp2 = $dir;
$dirtemp2 =~ s/\.{2}/new/g;
my $dirnew ="diffpack/".$dirtemp2;
#print ">>>>>>> $dirnew\n";
my $strold = $params{"old"};
my $stroldupper = $strold;
$stroldupper =~ tr/a-z/A-Z/;
my $strold_ = $strold; 
$strold_ =~ tr/_/-/;
    if(-e $dirnew){
    	#  die "path diffpack already has created, plz rename diffpack or deleted\n"
    }else{
      #  mkdir $dirnew or die "newdir not exit\n";        
    }
    
 #   if(!(-e $dirold)){
  #      make_path($dirold) or die "olddir not exit\n";        
  #  }

push(@DIRS,$dir);
&boardcopyout();

 #   if(!(-e $dirnew.$separator."old")){
  #      make_path($dirnew.$separator."old") or die "olddir not exit\n";
  #  }

#rename($dirnew.$separator.$dirtemp,$dirnew.$separator."new");
#dircopy($dirnew.$separator.$dirtemp.$separator."..", $dirnew.$separator."old");
#dircopy($dirnew.$separator."old", $dirnew.$separator."new");
#remove_tree($dirnew.$separator.$dirtemp.$separator."..");

remove_tree("diffpack/new/new");
dircopy("diffpack/new", "diffpack/old");


sub getboardkey()
{
		my ($curfile) = @_;
		print  "get board key: $curfile\n";
		open(FILEHANDLE,"+<".$curfile) or die " 2 cann't open $curfile!\n";
		open(FILETEMP,">>boardkey.txt") or die " 2 cann't open  boardkey!\n";
		my $line;
		my @ToProcess = <FILEHANDLE>;  

		foreach $line(@ToProcess)  
		{ 
				if($line =~ /CHIPRAM_DEFCONFIG\s*:=\s*sp(\w+|_*)/)
				{       
					print  ">>>> $1 $line \n";
					print FILETEMP "CHIPRAM ".$1."\n";
				}elsif($line =~ /UBOOT_DEFCONFIG\s*:=\s*sp(\w+|_*)/)
				{
					print  ">>>> $1 $line \n";
                                        print FILETEMP "UBOOT ".$1."\n";
				}
				
		}
		close(FILEHANDLE);
		close(FILETEMP);

}

sub boardcopyout()
{
    my $dir = pop(@DIRS);
    opendir(DIRHANDLE,$dir) or die "cann't open $dir!\n";

     while($file = readdir DIRHANDLE) 
    {
				my $curfile = $dir.$separator.$file; #absolute path
				if (-d $curfile) 
				{
						if(($file=~ /$strold/)||($file=~ /$strold_/))
						{
							#make_path($curfile);
							print  "dir:$curfile\n";
							dircopy($curfile,$dirnew.$separator.$curfile);
						}
						push(@DIRS, $curfile)  if(($file ne ".") && ($file ne "..")  &&($file !~ /.git/));
				}
				elsif(-l $curfile)
				{
					 print  "link:$curfile\n";
				}else{
						if($curfile =~ /sp$strold\/sp$strold.+.mk/)
						{
							  unlink "boardkey.txt";
							  &getboardkey($curfile);
						}
       			  
						if(($file=~ /$strold/)||($file=~ /$strold_/))
          					{	
	 						print  "files: $curfile\n"; 
							fcopy($curfile,$dirnew.$separator.$curfile);	
	    					}

                				open(FILEHANDLE, $curfile) or die "cann't open $curfile!\n";
               	 				my $lines=1;
                				while (<FILEHANDLE>) 
                				{
                   					chomp;
		   					if(/$strold|$strold_|$stroldupper/ ){
                   						print "$curfile:line $lines:$_\n";
								fcopy($curfile,$dirnew.$separator.$curfile);
		   					}
                    				$lines++;
						}
                				close(FILEHANDLE);
        			}
    }
    closedir(DIRHANDLE);
    &boardcopyout() if(@DIRS >0);
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
