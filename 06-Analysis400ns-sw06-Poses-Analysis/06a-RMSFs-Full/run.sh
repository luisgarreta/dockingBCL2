#rmsf-ALL.py "trajectories"
create-longtable-generic.py "out-rmsf" "rmsfs-calfa.csv" "POSE, RESID, RMSF" "RMSFs-trajectories.csv"
plot-XY-generic.R "RMSFs-trajectories.csv" RESID RMSF "RMSF for protein CAs" "Residue No." "RMSF(A)"
