INPUTDIR="trajectories"
#rmsds-trajectory-ALL.py $INPUTDIR 
plot-XY-generic-MULTI.R "out-rmsds/RMSDs-trajectories.csv" FRAME RMSD "TIME (ns)" "RMSD(A)" "Plot for RMSDs"
