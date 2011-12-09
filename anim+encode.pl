#!/usr/bin/perl -w

# Copyright (C) 2007, 2008 Guido De Rosa <guido_derosa@libero.it>
# License: MIT

# Split one big (Maxima->Gnuplot) data file by "time"
# i.e.: one file, one plot, one frame for animation...

#use Data::Dumper;
use File::Basename;
use IO::Handle;

use strict;

# Configuration
my $gnuplot     =   "gnuplot"; # /usr/bin/gnuplot, C:\Gnuplot\GNUPLOT.EXE etc.
my ($x1,$x2)    =   (5, 5.1); # barrier
my $xrange      =   "[-2:10]";
my $yrange      =   "[-.45:.45]";
my $zrange      =   "[-.4:.5]"; 
my $smscale     =    6; # scaling factor for plotting |psi(x)|^2 on z axis

autoflush STDOUT 1;
autoflush STDERR 1;
      
my ($infile, $sizex, $sizey) = @ARGV or 
die ("Usage: $0 {file.dat} [ size-X size-Y ]\n");

my ($name,$path,$ext) = fileparse($infile,".[a-zA-Z0-9]*");
$name =~ s/\.[^\.]+$//; # remove extension

my $datadir     =   "$infile.d";
my $imgdir;
if ($sizex and $sizey) {
    $imgdir      =   "$datadir/img-$sizex"."x$sizey";
} else {
    $imgdir      =   "$datadir/img";
}

my %handles = ();
my ($t, $n, $line, $fh, $file);

sub preamble ;
sub videncode ;
sub message ;

-d $datadir or mkdir $datadir;
-d $imgdir or mkdir $imgdir;

open(FH,"<$infile");

while(<FH>) {
    chomp;
    if (m/^\s*(\d*\.\d+)/) {
        $line = $_;
        $t = $1;
        $n = sprintf("%07.4f",$t);
        $file = "$datadir/$n$ext";
        unless ($handles{"$n"}) {
            message("splitting: $n$ext ...  \r");
            open($handles{"$n"},">$file") or die ("Couldn't open $file: $!\n");
            #print Dumper(\%handles),"\n";
        }
        $fh = $handles{"$n"};
        print $fh "$line\n";
    }
}

message("\n");

open(GNUPLOT,"|$gnuplot");

autoflush GNUPLOT 1;

preamble();

foreach $n (sort(keys(%handles))) {
    $fh = $handles{$n};
    close($fh);
    message("plotting: $n.png ...   \r");
    print GNUPLOT "set output \"$imgdir/$n.png\"\n";
    print GNUPLOT "splot \"$datadir/$n$ext\" using 2:3:4 w lines, ".
    " \"$datadir/$n$ext\" using 2:(0):($smscale*(\$3**2 + \$4**2)) w lines,".
    " $x1, u, v w lines, $x2, u, v w lines\n";
}

close(GNUPLOT);
     
videncode();

sub preamble {
    print GNUPLOT "reset\n";
    if ($sizex and $sizey) {
        print GNUPLOT "set terminal png crop small size $sizex, $sizey\n";
    } else {
        print GNUPLOT "set terminal png crop small\n";    
    }
    print GNUPLOT <<EOF
set parametric
set ticslevel 0
set xrange$xrange
set yrange$yrange 
set zrange$zrange 
set urange$yrange 
set vrange$zrange
set isosamples 2

EOF
}

sub videncode {
    # You will need mplayer and ffmpeg2theora 
    # http://www.mplayerhq.hu/  http://www.v2v.cc/~j/ffmpeg2theora/
    #
    # WARNING: uses named pipes for encoding Ogg/Theora: if you use
    # M$ Windows probably you need something based on Win32::Pipe;
    # contributions are welcome
    
    message("\nencoding videos... ");

    my $mencoder = "mencoder";
    my $mplayer = "mplayer";
    my $ffmpeg2theora = "ffmpeg2theora";
    my $ffmpeg = "ffmpeg";
    my $videodir;
    my $mpverbosity = ""; # "-msglevel all=-1:avsync=5";

    if ($sizex and $sizey) {
        $videodir = "$datadir/video-$sizex"."x$sizey";
    } else {
        $videodir = "$datadir/video";
    }

    my $uri             = "mf://$imgdir/*.png";
    my $lossless        = "$videodir/$name-lossless.avi";
    my $ogghq           = "$videodir/$name-hq.ogg";
    my $ogglq           = "$videodir/$name-lq.ogg";
    my $mpeg            = "$videodir/$name.mpg";
    my $mpeglq          = "$videodir/$name-lq.mpg";
    my $mp4             = "$videodir/$name.mp4";
    my $mp4lq           = "$videodir/$name-lq.mp4";
    my $avi             = "$videodir/$name.avi";
    my $flv             = "$videodir/$name.flv";

    my $theoralq        = 56; # low bitrate for theora 

    mkdir "$videodir";

    # encode an intermadiate, lossless file (better solution than 
    # writing to a VERY BIG yuv file, or using named pipes):
    system("$mencoder $uri -o $lossless -ovc lavc -lavcopts vcodec=ffv1 $mpverbosity");

#    # encode OGG/Theora video
#    # @different qualities
##    system("$ffmpeg2theora -o $ogghq -K 8 -S 0 -v 10 -V 16778 --optimize $lossless");
#    system("$ffmpeg2theora -o $ogghq -S 0 -v 10 --optimize $lossless"); 
#
#    system("$ffmpeg2theora -o $ogglq -S 0 -V $theoralq --optimize $lossless"); 
#
#    # MPEG1 and MPEG4
#    system("$ffmpeg -y -i $lossless $mpeg");
#    system("$ffmpeg -y -i $lossless $mp4");
#    system("$ffmpeg -y -b 1 -i $lossless $mpeglq");
#    system("$ffmpeg -y -b 1 -i $lossless $mp4lq");
#      
#    # Optional, proprietary formats/codecs:
#    
#    # encode a "Microsoft-friendly" AVI/M$MPEG4v2 video
#    # http://lists.mplayerhq.hu/pipermail/mencoder-users/2006-November/004562.html
#    system("$mencoder $uri -ovc lavc -lavcopts vcodec=msmpeg4v2:mbd=2:keyint=5:subcmp=2:dia=2:mv0:autoaspect -ofps 24 -o $avi $mpverbosity");
#
#    # encode a Macromedia Flash Video: never tested with a flash player ..
#    #system("$mencoder $uri -o $flv -ovc lavc -lavcopts vcodec=flv -of lavf -lavfopts format=flv:i_certify_that_my_video_stream_does_not_use_b_frames");
#
}

sub message {
    #print STDERR @_;
    print @_;
}
