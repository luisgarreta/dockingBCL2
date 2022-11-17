#INPUTDIR="trajectories"
#interaction-energies-ALL.py $INPUTDIR
filter-interactions.py "ienergies"
HEADERS="Pose, FRAME, RESIDUE, INTERACTION, VALUE"
create-longtable-generic.py "ienergies" "interaction-energies-FILTERED.csv" "$HEADERS" "interaction-energies-all-FILTERED.csv"
interaction-energies-plot.R "interaction-energies-all-FILTERED.csv"
