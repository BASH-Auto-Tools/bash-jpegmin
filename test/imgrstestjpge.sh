#!/bin/bash

if [ -z "$1" ]
then
    echo "Usage $0 <image>"
    exit 1
else
    src="$1"
fi

if [ ! -f "$src" ]; then
    echo "File $src does not exist"
    exit 1
fi

if [ ! -f "/usr/bin/convert" ]; then
    echo "Not found convert utility (imagemagick)!"
    exit 1
fi
if [ ! -f "/usr/bin/jpge" ]; then
    echo "Not found jpge utility (jpge)!"
    exit 1
fi

function imgrstest
{
	src="$1"
	tmpfile="$2"
	logfile="$src-imgrstestjpge.log"
	echo "$src" > "$logfile"
	srcfileedge="$tmpfile.0.edge.png"
	tmpfileedge="$tmpfile.q.edge.png"
	convert -edge 3 "$src" "$srcfileedge"
	q=1
	qmax=100
	while [ $q -le $qmax ]
	do
		jpge "$src" "$tmpfile" $q
		convert -edge 3 "$tmpfile" "$tmpfileedge"
		cmppct=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
		cmppct=`echo "1-sqrt(1-$cmppct)" | bc`
		echo "$q,0$cmppct"
		echo "$q,0$cmppct" >> "$logfile"
		q=$((q+1))
	done
	rm "$srcfileedge"
	rm "$tmpfileedge"
	rm "$tmpfile"
}

tmpfile="/tmp/imgmin$$.jpg"
imgrstest "$src" "$tmpfile"

