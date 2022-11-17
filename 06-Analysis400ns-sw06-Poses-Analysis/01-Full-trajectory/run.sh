#!/bin/bash
# Create full DCD trajectory from partial DCDs in NAMD charmmguis dir 

INPUTDIR="charmmguis"
NAMDOUTS="out-namds"
OUTPUTDIR="out-trajs"

get-trajectories-charmguis.py $INPUTDIR $NAMDOUTS
create-trajectory-from-steps.py $NAMDOUTS $OUTPUTDIR
