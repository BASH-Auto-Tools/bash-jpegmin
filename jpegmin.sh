#!/bin/bash
#
# Image minimizer
# Iteratively resamples image quality to a certain threshold, reducing image filesize but retaining quality similar to the original image
#
# Example usage:
#	./jpegmin.sh foo-before.jpg [foo-after.jpg]
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
    echo "Usage $0 <image> [dst]"
    exit 1
else
    src="$1"
fi

if [ -z "$2" ]
then
    dst="$src-jpegmin.jpg"
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
	srcfile="$tmpfile-trim.png"
	uc=`convert "$src" -format "%k" info:-`
	echo "$src uc=$uc"
	qmin=50
	qmax=100
	srcfileedge="$tmpfile.0.edge.png"
	tmpfileedge="$tmpfile.q.edge.png"
	convert -edge 3 "$src" "$srcfileedge"
	convert -quality $qmin "$src" "$tmpfile"
	convert -edge 3 "$tmpfile" "$tmpfileedge"
	cmpmin=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
	cmpmin=`echo "$qmin*0.01-1+sqrt(1-$cmpmin)" | bc`
	echo "$qmin -> $cmpmin"
	convert -quality $qmax "$src" "$tmpfile"
	convert -edge 3 "$tmpfile" "$tmpfileedge"
	cmpmax=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
	cmpmax=`echo "$qmax*0.01-1+sqrt(1-$cmpmax)" | bc`
	echo "$qmax -> $cmpmax"
	echo "----------------"
	cmppctb=`echo "$cmpmax < $cmpmin" | bc`
	if [ $cmppctb -eq 1 ]; then
		cmpmax=$cmpmin
	fi
	# binary search for lowest quality where compare < $cmpthreshold
	while [ $qmax -gt $((qmin+1)) ]
	do
		q=$(((3*qmax+2*qmin+1)/5))
		convert -quality $q "$src" "$tmpfile"
		convert -edge 3 "$tmpfile" "$tmpfileedge"
		cmppct=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
		cmppct=`echo "$q*0.01-1+sqrt(1-$cmppct)" | bc`
		cmppctb=`echo "$cmpmax < $cmpmin" | bc`
		if [ $cmppctb -eq 1 ]; then
			qmax=$q
			cmpmax=$cmppct
		else
			qmin=$q
			cmpmin=$cmppct
		fi
		echo "$q -> $cmppct"
	done
	cmppctb=`echo "$cmpmax < $cmpmin" | bc`
	if [ $cmppctb -eq 1 ]; then
		q=$qmin
		cmppct=$cmpmin
	else
		q=$qmax
		cmppct=$cmpmax
	fi
	echo "----------------"
	convert -quality $q "$src" "$tmpfile"
	echo "$q -> $cmppct"
	rm "$srcfileedge"
	rm "$tmpfileedge"
}

function print_stats
{
	k0=$((`stat -c %s $src` / 1024))
	k1=$((`stat -c %s $tmpfile` / 1024))
	kdiff=$((($k0-$k1) * 100 / $k0))
	if [ $kdiff -eq 0 ]; then
		k1=$k0
		kdiff=0
	fi
	echo "Before:${k0}KB After:${k1}KB Saved:$((k0-k1))KB($kdiff%)"
	echo ""
	return $kdiff
}

ext=${src:(-3)}
tmpfile="/tmp/imgmin$$.jpg"
search_quality "$src" "$tmpfile"
convert -strip "$tmpfile" "$dst"
#cp "$tmpfile" "$dst"
print_stats
rm -f $tmpfile
