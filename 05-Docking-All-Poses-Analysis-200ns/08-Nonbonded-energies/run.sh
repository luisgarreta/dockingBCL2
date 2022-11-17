#!/bin/bash
module load NAMD
nonbonded-energies-ALL.py trajectories $PWD/toppar
nonbonded-energies-tables.py nbenergies
nonbonded-energies-plots.R nonbonded-energies-all-values.csv

