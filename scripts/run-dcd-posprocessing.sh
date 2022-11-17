#!/bin/bash
# Postprocessing of docking simulations:
#   - Create movies from trajectories
#   - Calculates free binding energies 

NAMDOUTS="namdouts"
TRAJECTORIES="trajectories"
FRAMES="frames"
md-dcd-create-trajectory-from-steps.py $NAMDOUTS  # Create "trajectories" dir
md-dcd-create-trajectory-movies.py $TRAJECTORIES
md-dcd-create-frames-trajectory.py $TRAJECTORIES  # Create frames into each subdir
calculate_binding_energies-AllFrames.py $FRAMES
create_binding_energies_table.py $FRAMES

# Calculate and plot RMSDs
TRAJECTORIES="trajectories"
RMSDS="rmsds"
rmsds-multiple-trajectories.py $TRAJECTORIES
plot-XY-multi.R $RMSDS/trajectories-RMSDs.csv
