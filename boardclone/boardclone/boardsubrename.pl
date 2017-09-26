#! /usr/bin/perl  
##############################################################################
#
#   File          : boardrename.pl
#   Author(s)     : xiaotong.lu <enck@spreadtrum.com>
#   Description   : rename ref board name to new board name in diffpack/new 
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
die "lack params error/n" if(!exists($params{"dir"}) || !exists($params{"old"})|| !exists($params{"new"}));

my $SYSTEM;
my $separator;
my $file;
my $dir;
my $strnew;
my $strold;
my $strnew_;
my $strold_;
my @DIRS;
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

$strold = $params{"old"};
$strnew =  $params{"new"};

$strnew_ = $strnew;
$strold_ = $strold; 

$strnew_ =~ tr/_/-/;
$strold_ =~ tr/_/-/;
my $strold_native = $strold."_native";
my $strold_common = $strold."_common";
print "xiaotong $strold_native\n";
my $strnewupper = $strnew;
my $stroldupper = $strold;

$strnewupper =~ tr/a-z/A-Z/;
$stroldupper =~ tr/a-z/A-Z/;

$dir = $params{"dir"};
push(@DIRS,$dir);
&boardcheck();
splice(@DIRS);
$dir = $params{"dir"};
print "boardrename $dir\n";
push(@DIRS,$dir);
&boardrename();
exit(0);

sub boardrenamecore()
{
		my ($curfile) = @_;
		print  "boardrenamecore: $curfile\n";
		open(FILEHANDLE,"+<".$curfile) or die " 2 cann't open $curfile!\n";
		my $line;
		my $counter = 0;
		my @ToProcess = <FILEHANDLE>;

		foreach $line(@ToProcess)
		{
			chomp $line;
			if(($line !~ /$strnew/) && ($line !~ /$strold_common/))
			{
				if(($line =~ s/$strold/$strnew/g)||($line =~ s/$strold_/$strnew_/g)||($line =~ s/$stroldupper/$strnewupper/g))  
				{
						$ToProcess[$counter]=$line;
						print  "$curfile\n";
				}
			}
			$counter++;
		}

		seek FILEHANDLE , 0,0;
		print FILEHANDLE join "\n",@ToProcess; 
		close(FILEHANDLE);

}

sub boardcheck()
{
    my $filetemp;
    my $dir = pop(@DIRS);
    opendir(DIRHANDLE,$dir) or die "cann't open $dir!\n";
    #if(!(-e $dirnew)){
    #    mkdir $dirnew or die;
    #}

		while($file = readdir DIRHANDLE)
		{
				my $curfile = $dir.$separator.$file; #absolute path
				if (-d $curfile)
				{
						$filetemp = $file;
						if($filetemp=~ /$strnew/)
						{
							print "$curfile\n";
							print ">>>> your board already created\n";
							exit(4);
						}


				push(@DIRS, $curfile)  if(($file ne ".") && ($file ne ".."));
				}
		}
		closedir(DIRHANDLE);
    &boardcheck() if(@DIRS >0);
}

sub boardrename()
{
    my $filetemp;
    my $curfile;
    my $dir = pop(@DIRS);
    opendir(DIRHANDLE,$dir) or die "cann't open $dir!\n";
    #if(!(-e $dirnew)){
    #    mkdir $dirnew or die;
    #}

		while($file = readdir DIRHANDLE)
		{
				$curfile = $dir.$separator.$file; #absolute path
				$filetemp = $file;
				if (-d $curfile)
				{

						#if($filetemp=~ s/$strold/$strnew/g)
						#{
								print  "dir:$curfile\n";
						#		rename ($dir.$separator.$file,$dir.$separator.$filetemp);
						#		$curfile = $dir.$separator.$filetemp;
								#dircopy($curfile,$dirnew.$dir.$separator.$file);     
						#}

				push(@DIRS, $curfile)  if(($file ne ".") && ($file ne ".."));
				}
				else
				{
					if($filetemp =~ /$strnew/ || $filetemp =~ /$strnew_/ || $filetemp =~ /$strold_common/){
					}else
					{
						if(($filetemp =~ s/$strold_native/$strnew/g)||($filetemp =~ s/$strold/$strnew/g) || ($filetemp =~ s/$strold_/$strnew_/g))
						{
								print  "files: $curfile\n";
								rename ($dir.$separator.$file,$dir.$separator.$filetemp);
						}
					}
					$curfile = $dir.$separator.$filetemp;
					&boardrenamecore($curfile);
        			}
    		}
    		closedir(DIRHANDLE);
    		&boardrename() if(@DIRS >0);
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
