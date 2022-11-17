#rmsf-ALL.py "trajectories"
create-longtable-generic.py "out-rmsf" "rmsfs-calfa.csv" "POSE, RESID, RMSF" "RMSFs-trajectories.csv"
plot-XY-generic.R "RMSFs-trajectories.csv" RESID RMSF "Residue No." "RMSF(A)" "RMSF for protein CAs" 
