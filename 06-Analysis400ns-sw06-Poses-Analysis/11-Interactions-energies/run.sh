INPUTDIR="trajectories"
OUTPUTDIR="out-ienergies"
#interaction-energies-ALL.py $INPUTDIR
HEADERS="Pose, FRAME, RESIDUE, INTERACTION, VALUE"
#create-longtable-generic.py $OUTPUTDIR "interaction-energies.csv" "$HEADERS" "interaction-energies-all.csv"
interaction-energies-plot.R "interaction-energies-all.csv"
