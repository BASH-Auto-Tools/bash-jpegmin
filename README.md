JPEGMIN (Bash Script).

The script uses the ImageMagick to determine the best indicator of quality when converting lossless images to jpeg.
For calculations using BC.

As a criterion for visual quality using correlation analysis of the state borders:

		convert -quality $q "$src" "$tmpfile"
		convert -edge 3 "$tmpfile" "$tmpfileedge"
		cmppct=`compare -metric NCC "$srcfileedge" "$tmpfileedge" /dev/null 2>&1

In terms of the correlation A correlation is based sigmoid:

    NCCsigma=`echo "1-sqrt(1-$cmppct)" | bc`

Avoiding the correlation sigmoid from linearity well characterizes the state borders.
In this particular case, the maximum deviation interested in q=60-100.

    		cmppct=`echo "$q*0.01-1+sqrt(1-$cmppct)" | bc`

It characterizes the beginning of the process avoidance of artifacts at the borders.

PS:
State borders - is not the only factor that determines the visual quality.
Possible combined application and other filters for activating factors unrelated to the boundaries.

jpegmin-zt-test:

bash jpegmin-zt.sh lena.png  
![lena.png](https://raw.githubusercontent.com/zvezdochiot/bash-jpegmin/master/images/lena.png)  
_lena-png_

result:

![lena-jpegmin.jpg](https://raw.githubusercontent.com/zvezdochiot/bash-jpegmin/master/images/lena-jpegmin.jpg)  
_lena-jpegmin.jpg_

88 -> .342574  
Before:462KB After:58KB Saved:404KB(87%)

index:

bash jpemin-zt-test.sh lena.png  
![test-lena.png](https://raw.githubusercontent.com/zvezdochiot/bash-jpegmin/master/images/test-lena.png)  
_lena-jpegmin.csv_

