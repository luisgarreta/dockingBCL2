#!/usr/bin/bash
get-energies-multiple-files.py namd "(step7.*out)"

mv energies-all-files.csv energies-production.csv

plot-thermodynamics-energies.R energies-production.csv
