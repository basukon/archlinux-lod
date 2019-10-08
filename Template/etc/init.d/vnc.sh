#!/bin/sh

VNCBIN=/usr/bin/vncserver

rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 
rm -f /share/run/vncsrv.usk 

$VNCBIN -kill :1

/usr/bin/lod_daemon &

sudo -i -u $3 $VNCBIN -geometry $1 -dpi $2 -depth 24 \
	-SecurityTypes None -localhost :1 -improvedhextile 0 \
	-framerate 60 -comparefb 0 
                                      
while : ; do sleep 1 ; done #sleep forever until the parent dies
