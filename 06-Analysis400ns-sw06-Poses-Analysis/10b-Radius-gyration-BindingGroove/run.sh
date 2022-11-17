INPUTDIR="trajectories"
OUTPUTDIR="out-radiog"
RadioGyration-ALL.py $INPUTDIR
create-longtable-generic.py $OUTPUTDIR "radio-gyration.csv" "POSE, TYPE, FRAME, RADIOG" "radiogyration-all.csv"
plot-XY-generic-MULTI.R "radiogyration-all.csv" FRAME RADIOG "TIME (ns)" "Radio of Gyration(A)" "Plot for Radio of Gyration"
