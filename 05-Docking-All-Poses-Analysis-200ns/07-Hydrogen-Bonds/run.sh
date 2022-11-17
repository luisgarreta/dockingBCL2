INPUTDIR="trajectories"
#hbonds-ALL.py $INPUTDIR
#create-longtable-generic.py "outhbonds" "hbonds.csv" "Pose, FRAME, HBONDS" "hbonds-trajectories.csv"
plot-XY-generic.R "hbonds-trajectories.csv" FRAME HBONDS "Hydrogen Bonds" "FRAME No." "HBONDS"
