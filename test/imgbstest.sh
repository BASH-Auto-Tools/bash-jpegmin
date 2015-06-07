#!/bin/bash

# Image blur-sharpen test (noise immunity)

function usage() {
    cat << EOF
    Usage: $0 {input image}

    Sample: $0 example.jpg [R] [E]

EOF
}
if [ $# -eq 0 ] ; then
    usage
    exit 1
fi

src="$1"
if [ -z "$2" ]
then
    trd="5"
else
    trd="$2"
fi
if [ -z "$3" ]
then
    ted="1"
else
    ted="$3"
fi

convert -blur "$trd" -edge "$ted" -normalize "$src" /tmp/temp-blure.png
convert -sharpen "$trd" -edge "$ted" -normalize "$src" /tmp/temp-sharpene.png
tcm=`compare -metric NCC "/tmp/temp-blure.png" "/tmp/temp-sharpene.png" /dev/null 2>&1`
rm "/tmp/temp-blure.png"
rm "/tmp/temp-sharpene.png"
echo "R:$trd,E:$ted,r2:$tcm  $src"