#!/bin/bash
#
# Image minimizer (zeroface)
# Iteratively resamples image quality to a certain threshold, reducing image filesize but retaining quality similar to the original image
#
# Example usage:
#	./jpegmin-cs.sh foo-before.png [foo-after.jpg]
#
# Author: Ryan Flynn <parseerror+imgmin@gmail.com>
# Modify: zvezdochiot <mykaralw@yandex.ru>
#
# Requires:
#  Imagemagick tools 'convert' and 'compare' http://www.imagemagick.org/
#
# References:
#   1. "Optimization of JPEG (JPG) images: good quality and small size", Retrieved May 23 2011, http://www.ampsoft.net/webdesign-l/jpeg-compression.html
#   2. "Convert, Edit, Or Compose Images From The Command-Line" In ImageMagick, Retrieved May 24 2011, http://www.imagemagick.org/script/command-line-tools.php
#   3. "Bash Floating Point Comparison", http://unstableme.blogspot.com/2008/06/bash-float-comparison-bc.html
#
# Depends:
#  imagemagick

# needed for webservers
PATH=$PATH:/usr/local/bin:/usr/bin # FIXME: be smarter

if [ -z "$1" ]
then
    echo "Usage $0 <image> [csv]"
    exit 1
else
    src="$1"
fi

if [ -z "$2" ]
then
    dst="${src%.*}-jpegmin.csv"
else
    dst="$2"
fi

if [ ! -f "$src" ]; then
    echo "File $src does not exist"
    exit 1
fi

if [ ! -f "/usr/bin/convert" ]; then
    echo "Not found convert utility (imagemagick)!"
    exit 1
fi

function search_quality
{
	src="$1"
	tmpfile="$2"
	dest="$3"
	echo "jpegmin-zt: $src" > "$dest"
	srcfileedge="$tmpfile.0.edge.ppm"
	tmpfileedge="$tmpfile.q.edge.ppm"

	convert -edge 3 "$src" "$srcfileedge"

	q100=100
	convert -quality $q100 "$src" "$tmpfile"
	convert -edge 3 "$tmpfile" "$tmpfileedge"
	rs100=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
	rs100=`echo "1-sqrt(1-$rs100)" | bc`
	echo "$q100 -> $rs100"
	kq=`echo "$rs100*0.01" | bc`
	echo "kq -> $kq"
	echo "----------------"

	q=0
	qmax=100
	while [ $q -lt $qmax ]
	do
		q=$((q+1))
		convert -quality $q "$src" "$tmpfile"
		convert -edge 3 "$tmpfile" "$tmpfileedge"
		cmppct=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
		cmppct=`echo "$q*$kq-1+sqrt(1-$cmppct)" | bc`
		echo "$q - $cmppct"
		echo "$q,$cmppct" >> "$dest"
	done
}

ext=${src:(-3)}
tmpfile="/tmp/imgmin$$.jpg"
search_quality "$src" "$tmpfile" "$dst"
rm -f $tmpfile

