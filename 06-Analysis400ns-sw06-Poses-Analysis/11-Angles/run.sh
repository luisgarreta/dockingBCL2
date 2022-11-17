FRAMESDIR="out-frames"
angles-trajectory-H3H4.py $FRAMESDIR
plot-XY-generic.R  "angles-trajectory-H3H4.csv" "FRAME" "ANGLE" "TIME (ns)" "ANGLE (Degrees)" "Angles for helices H3 and H4 in binding groove"
