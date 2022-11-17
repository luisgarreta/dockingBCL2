INPUTDIR="trajectories"
#hbonds-ALL.py $INPUTDIR
#create-longtable-generic.py "out-hbonds" "hbonds.csv" "Pose, FRAME, HBONDS" "hbonds-trajectories.csv"
plot-XY-generic.R "hbonds-trajectories.csv" FRAME HBONDS "Number of Hydrogen Bonds" "TIME (ns)" "Number of Hydrogen Bonds"
