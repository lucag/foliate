#!/bin/sh
# PROTOTYPE asset generator for the dark-mode pages prototype. Throwaway.
set -e
cd "$(dirname "$0")"
# a photo-like picture: plasma clouds over a sky gradient, blurred
magick -font /System/Library/Fonts/Supplemental/Arial.ttf -size 640x420 -seed 7 plasma:tomato-steelblue -blur 0x2 \
  \( -size 640x420 gradient:'#7fb2e5'-'#e8c07a' \) -compose overlay -composite \
  -modulate 100,140 -quality 88 photo.jpg
# transparent line art, black ink: a geometry figure
magick -font /System/Library/Fonts/Supplemental/Arial.ttf -size 480x320 xc:none -stroke black -strokewidth 4 -fill none \
  -draw "circle 160,160 160,40" -draw "line 40,280 440,280" -draw "line 160,160 300,60" \
  -draw "polyline 300,60 440,280 160,160" -strokewidth 0 -fill black \
  -pointsize 30 -draw "text 300,50 'B'" -draw "text 445,300 'C'" -draw "text 130,190 'A'" lineart.png
# opaque line art on white paper (a scanned figure as JPEG)
magick -font /System/Library/Fonts/Supplemental/Arial.ttf -size 480x260 xc:white -stroke '#111' -strokewidth 3 -fill none \
  -draw "rectangle 30,30 200,120" -draw "rectangle 280,140 450,230" -draw "line 200,75 365,75" \
  -draw "line 365,75 365,140" -strokewidth 0 -fill '#111' -pointsize 22 \
  -draw "text 60,82 'Input'" -draw "text 320,192 'Output'" -quality 85 diagram-on-white.jpg
# gaiji: a small transparent glyph image
magick -font /System/Library/Fonts/Supplemental/Arial.ttf -size 64x64 xc:none -fill black -font "/System/Library/Fonts/Supplemental/Arial Unicode.ttf" -pointsize 56 -gravity center -draw "text 0,0 '※'" gaiji.png 2>/dev/null || \
magick -font /System/Library/Fonts/Supplemental/Arial.ttf -size 64x64 xc:none -fill black -stroke black -strokewidth 6 -draw "line 10,10 54,54" -draw "line 54,10 10,54" -draw "point 32,4" gaiji.png
# colour chart PNG with few saturated colours (should be left alone)
magick -font /System/Library/Fonts/Supplemental/Arial.ttf -size 360x200 xc:white -fill '#d62728' -draw "rectangle 30,120 90,180" -fill '#1f77b4' \
  -draw "rectangle 110,60 170,180" -fill '#2ca02c' -draw "rectangle 190,90 250,180" -fill '#ff7f0e' \
  -draw "rectangle 270,30 330,180" chart.png
# the PostScript text page: text, a vector colour chart and an embedded photo
W=$(magick identify -format %w photo.jpg); H=$(magick identify -format %h photo.jpg)
cat > textpage.ps <<PS
%!PS
<< /PageSize [612 792] >> setpagedevice
/Times-Bold findfont 20 scalefont setfont 60 730 moveto (3. Results and Discussion) show
/Times-Roman findfont 11 scalefont setfont
/y 705 def
[ (The measurements in Figure 3 show the response of the three samples over the full range.)
  (Sample A (red) peaks early, while B (blue) and C (green) follow a slower curve. The photo)
  (below shows the field site where the samples were collected in the spring.) ]
{ 60 y moveto show /y y 14 sub def } forall
% chart frame
0.6 setgray 0.5 setlinewidth
0 1 4 { /i exch def 90 480 i 30 mul add moveto 330 0 rlineto stroke } for
0 setgray 1.2 setlinewidth 90 480 moveto 0 130 rlineto stroke 90 480 moveto 340 0 rlineto stroke
% bars
0.84 0.15 0.16 setrgbcolor 110 480 40 100 rectfill
0.12 0.47 0.71 setrgbcolor 170 480 40 70 rectfill
0.17 0.63 0.17 setrgbcolor 230 480 40 115 rectfill
1.0 0.5 0.05 setrgbcolor 290 480 40 50 rectfill
% a red curve
0.84 0.15 0.16 setrgbcolor 2 setlinewidth 100 500 moveto 160 590 220 520 420 600 curveto stroke
0 setgray /Helvetica findfont 9 scalefont setfont
110 468 moveto (A) show 170 468 moveto (B) show 230 468 moveto (C) show 290 468 moveto (D) show
/Times-Italic findfont 10 scalefont setfont 90 450 moveto (Figure 3. Response by sample.) show
% the photo
gsave 90 140 translate 320 210 scale
/DeviceRGB setcolorspace
<< /ImageType 1 /Width $W /Height $H /BitsPerComponent 8 /Decode [0 1 0 1 0 1]
   /ImageMatrix [$W 0 0 -$H 0 $H] /DataSource (photo.jpg) (r) file /DCTDecode filter >> image
grestore
/Times-Italic findfont 10 scalefont setfont 90 125 moveto (Figure 4. The field site, looking north.) show
/Times-Roman findfont 11 scalefont setfont /y 95 def
[ (Further work will extend the series to the autumn samples, with the same method.) ]
{ 60 y moveto show /y y 14 sub def } forall
showpage
PS
gs -q -dNOSAFER -sDEVICE=pdfwrite -o text.pdf textpage.ps
# the scanned page: a raster of a text page, with a greyscale photo, toned paper and noise
cat > scansrc.ps <<PS
%!PS
<< /PageSize [612 792] >> setpagedevice
/Times-Bold findfont 18 scalefont setfont 60 730 moveto (CHAPTER II) show
/Times-Roman findfont 12 scalefont setfont /y 700 def
[ (It was late in the afternoon when the travellers came at last to the river. The water)
  (ran high and brown with the spring rains, and the old ferryman shook his head when he)
  (saw them. No boat would cross that day, he said, nor the next, unless the weather turned.)
  (They made camp in the lee of the hill and waited, watching the clouds go over.) ]
{ 60 y moveto show /y y 16 sub def } forall
/y 270 def
[ (By morning the rain had stopped. The ferryman, true to his word, was already at the)
  (landing, coiling rope, and he waved them down with something like a smile.) ]
{ 60 y moveto show /y y 16 sub def } forall
showpage
PS
gs -q -sDEVICE=pnggray -r150 -o scansrc.png scansrc.ps
magick photo.jpg -colorspace gray -resize 600x -sigmoidal-contrast 3x50% scanphoto.png
magick scansrc.png scanphoto.png -geometry +165+640 -composite \
  -attenuate 0.35 +noise gaussian -blur 0x0.6 -rotate 0.4 -background white -flatten \
  -colorspace sRGB -fill '#efe6d2' -tint 30 -fill '#f3ead6' -colorize 6 -quality 80 scan.jpg
magick scan.jpg -density 150 -units PixelsPerInch scan.pdf
rm -f scansrc.ps scansrc.png scanphoto.png textpage.ps
ls -la
