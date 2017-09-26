#! /usr/bin/perl
##############################################################################
#
#   File          : boardcopyin.pl
#   Author(s)     : xiaotong.lu <enck@spreadtrum.com>
#   Description   : copy the file of diffpack/new to dir
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
die "lack params error/n" if(!exists($params{"dir"}));

my $SYSTEM;
my $separator;
my $dir;

my $dirnew ="diffpack/new";

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
$dir = $params{"dir"};
print "$dir\n";

if(!(-e $dirnew)){
         die "diffpack  not exit \n";
}

dircopy($dirnew, $dir);
unlink "boardkey.txt";
print "copyin OK\n";

sub getParams()
{
   foreach(@ARGV)
   {
      chomp;
      my @sparams = split("=");
      $params{$sparams[0]}=$sparams[1];
   }
}
