#!/bin/bash
INPUTDIR="trajectories"
OUTPUDDIR="out-nbenergies"
TOPPARDIR="$PWD/toppar"
#module load NAMD
#nonbonded-energies-ALL.py $INPUTDIR $TOPPARDIR
#nonbonded-energies-tables.py $OUTPUDDIR
nonbonded-energies-plots.R nonbonded-energies-all-values.csv

