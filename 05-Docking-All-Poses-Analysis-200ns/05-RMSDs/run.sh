INPUTDIR="trajectories"
#rmsd-multiple-trajectories.py $INPUTDIR
#create-longtable-generic.py "out-radiog" "radio-gyration-long.csv" "POSE, TYPE, FRAME, RADIOG" "radiogiration-all.csv"
plot-XY-generic-MULTI.R "RMSDs-trajectories.csv" FRAME RMSD "FRAME No." "RMSD" "Plot for RMSDs"
