Quantum Mechanisc simulation: potential barrier with tunneling (and a 
somewhat sophisticated representation of complex values ^_^) 

This guide assumes you are a Linux/Unix user. Please contribute
your experience and/or "port" this guide to Windows, Mac, etc. 

Copyright 2007, 2008 Guido De Rosa <guidoderosa@gmail.com>

***

You will need:

Maxima
http://maxima.sourceforge.net/

Gnuplot
http://www.gnuplot.info/

MEncoder (provided by MPlayer)
http://www.mplayerhq.hu/

Perl (almost certainly already installed in your system)

***

HOWTO:

maxima -b tunnel.mxm

will produce a tunnel.[timestamp].dat datafile, with a timestamp 
in the filename to avoid accidental overwritings.

This will take a VERY LONG TIME, so a tunnel.dat is already included
for your convenience.

Gnuplot (to create png images) and MEncoder (to create a lossless avi video)
will be automatically invoked by the Perl script. 

perl anim+encode.pl <datafile> [X-size] [Y-size] 

Now you will find a bunch of new file and directories:

<datafile>.d/*.dat			datafile "splitted" in frames
<datafile>.d/img/*.png			animation frames (png image format)
<datafile>.d/video/*-lossless.avi	your video! (FFv1 lossless codec)

You can now manipulate your video with your favourite transcoder/video editor.

