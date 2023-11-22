#!/bin/sh

tmpd=/tmp/
image=$1
tjp2=$image.jp2

# base shell: opj_compress -i $tppm -o jp2/$tppm.jp2 -r 60,40,20

r1=3
r2=2
r3=1

tm=100
tq=1
tdq=8
tdm=1
tt="0.75"

anytopnm $image | pnmtopng > $tmpd$image.png

while [ $tdm -gt 0 ]
do
    tdm=$(echo "($tdq>1)" | bc)
    r1t=$(echo "$r1*$tq" | bc)
    r2t=$(echo "$r2*$tq" | bc)
    r3t=$(echo "$r3*$tq" | bc)
    opj_compress -i $tmpd$image.png -o $tmpd$tjp2 -r $r1t,$r2t,$r3t > /dev/null
    opj_decompress -i $tmpd$tjp2 -o $tmpd$tjp2.png > /dev/null

#    tmqs=$(stbimmetrics -m ssim -q -u $tmpd$image.png $tmpd$tjp2.png | cut -d" " -f 1)
    tmqv=$(stbimmetrics -m vifp1 -q -u $tmpd$image.png $tmpd$tjp2.png | cut -d" " -f 1)
#    tmqh=$(stbimmetrics -m shbad -q -u $tmpd$image.png $tmpd$tjp2.png | cut -d" " -f 1)
#    tmqn=$(stbimmetrics -m nhw-c -q -u $tmpd$image.png $tmpd$tjp2.png | cut -d" " -f 1)
#    tmq=$(echo "($tmqs+$tmqv+$tmqh+$tmqn)*0.25" | bc)
    tmq="$tmqv"
    echo "q = $tq ($r1t,$r2t,$r3t), UM = $tmq"
    tm=$(echo "($tmq>$tt)" | bc)
    if [ $tm -gt 0 ]
    then
        tdq=$(echo "$tdq*2" | bc)
        tq=$(echo "$tq+$tdq" | bc)
    else
        tdq=$(echo "$tdq/2" | bc)
        tq=$(echo "$tq-$tdq" | bc)
    fi
done

mv -v $tmpd$tjp2 $tjp2
rm -v $tmpd$image.png $tmpd$tjp2.png
