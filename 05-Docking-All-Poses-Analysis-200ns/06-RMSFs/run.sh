#rmsf-ALL.py "trajectories"
#create-longtable-generic.py "out-rmsf" "rmsfs-calfa.csv" "Pose, ResId, RMSF" "RMSFs-trajectories.csv"
plot-XY-generic.R "RMSFs-trajectories.csv" ResId RMSF "RMSF for protein CAs" Residues "RMSF(A)"
