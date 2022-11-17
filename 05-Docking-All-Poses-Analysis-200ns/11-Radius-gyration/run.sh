INPUTDIR="trajectories"
#RadioGyration-ALL.py $INPUTDIR
#create-longtable-generic.py "out-radiog" "radio-gyration-long.csv" "POSE, TYPE, FRAME, RADIOG" "radiogiration-all.csv"
plot-XY-generic-MULTI.R "radiogiration-all.csv" FRAME RADIOG "FRAME No." "Radio of Gyration" "Plot for Radio of Gyration"
