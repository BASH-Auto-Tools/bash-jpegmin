#!/bin/bash
#
# Image minimizer (zeroface)
# Iteratively resamples image quality to a certain threshold, reducing image filesize but retaining quality similar to the original image
#
# Example usage:
#	./mozjpegmin-cs.sh foo-before.png [foo-after.jpg]
#
# Author: Ryan Flynn <parseerror+imgmin@gmail.com>
# Modify: zvezdochiot <mykaralw@yandex.ru>
#
# Requires:
#  Imagemagick tools 'convert' and 'compare' http://www.imagemagick.org/
#  Research JPEG encoder https://github.com/pornel/jpeg-compressor
#  for debian:
#  - jessie - http://sourceforge.net/projects/debiannoofficial/files/jessie-update/graphics/jpge_0.1_i386.deb
#
# References:
#   1. "Optimization of JPEG (JPG) images: good quality and small size", Retrieved May 23 2011, http://www.ampsoft.net/webdesign-l/jpeg-compression.html
#   2. "Convert, Edit, Or Compose Images From The Command-Line" In ImageMagick, Retrieved May 24 2011, http://www.imagemagick.org/script/command-line-tools.php
#   3. "Bash Floating Point Comparison", http://unstableme.blogspot.com/2008/06/bash-float-comparison-bc.html
#
# Depends:
#  imagemagick, jpge

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
    dst="${src%.*}-jpgemin.jpg"
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
if [ ! -f "/usr/bin/jpge" ]; then
    echo "Not found jpge utility (jpge)!"
    exit 1
fi

function search_quality
{
	src="$1"
	tmpfile="$2"
	uc=`convert "$src" -format "%k" info:-`

	echo "$src uc=$uc"

	srcfileedge="$tmpfile.0.edge.png"
	tmpfileedge="$tmpfile.q.edge.png"

	convert -edge 3 "$src" "$srcfileedge"

#	q0=1
	q100=100
#	jpge "$src" "$tmpfile" $q0 1>/dev/null
#	convert -edge 3 "$tmpfile" "$tmpfileedge"
#	rs0=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
#	rs0=`echo "1-sqrt(1-$rs0)" | bc`
#	echo "$q0 -> $rs0"
	jpge "$src" "$tmpfile" $q100 1>/dev/null
	convert -edge 3 "$tmpfile" "$tmpfileedge"
	rs100=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
	rs100=`echo "1-sqrt(1-$rs100)" | bc`
	echo "$q100 -> $rs100"
#	kq=`echo "(($rs100)-($rs0))/($q100-$q0)" | bc -l`
	kq=`echo "$rs100*0.01" | bc`
	echo "kq -> $kq"
	echo "----------------"

	qmin=50
	qmax=100
	jpge "$src" "$tmpfile" $qmin 1>/dev/null
	convert -edge 3 "$tmpfile" "$tmpfileedge"
	cmpmin=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
#	cmpmin=`echo "($qmin-$q0)*$kq+$rs0-1+sqrt(1-$cmpmin)" | bc`
	cmpmin=`echo "$qmin*$kq-1+sqrt(1-$cmpmin)" | bc`
	echo "$qmin -> $cmpmin"
	jpge "$src" "$tmpfile" $qmax 1>/dev/null
	convert -edge 3 "$tmpfile" "$tmpfileedge"
	cmpmax=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
#	cmpmax=`echo "($qmax-$q0)*$kq+$rs0-1+sqrt(1-$cmpmax)" | bc`
	cmpmax=`echo "$qmax*$kq-1+sqrt(1-$cmpmax)" | bc`
	echo "$qmax -> $cmpmax"
	echo "----------------"
	# binary search for lowest quality where compare < $cmpthreshold
	while [ $qmax -gt $((qmin+1)) ]
	do
		cmppctb=`echo "$cmpmax < $cmpmin" | bc`
		if [ $cmppctb -eq 1 ]; then
			q=$(((4*qmax+qmin)/5))
		else
			q=$(((2*qmax+3*qmin)/5))
		fi
		if [ $q -eq $qmax ]; then
			q=$(((qmax-1)))
		fi
		if [ $q -eq $qmin ]; then
			q=$(((qmin+1)))
		fi
		jpge "$src" "$tmpfile" $q 1>/dev/null
		convert -edge 3 "$tmpfile" "$tmpfileedge"
		cmppct=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1`
#		cmppct=`echo "($q-$q0)*$kq+$rs0-1+sqrt(1-$cmppct)" | bc`
		cmppct=`echo "$q*$kq-1+sqrt(1-$cmppct)" | bc`
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
	echo "$q -> $cmppct"
	jpge "$src" "$tmpfile" $q
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
#convert -strip "$tmpfile" "$dst"
cp "$tmpfile" "$dst"
print_stats
rm -f $tmpfile

