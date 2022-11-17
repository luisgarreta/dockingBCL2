RMSD analysis - ligand
======================
Source: https://training.galaxyproject.org/archive/2022-05-01/topics/computational-chemistry/tutorials/htmd-analysis/tutorial.html#analysis

Calculating the RMSD of the ligand is necessary to check if it is stable in the active site and to identify possible binding modes. If the ligand is not stable, there will be large fluctuations in the RMSD.

For the RMSD analysis of the ligand, the Select domains parameter of the tool can for convenience be set to Ligand; however, this automatic selection sometimes fails. The other alternative, which we apply here, is to specify the Residue ID in the textbox provided. In this example the ligand’s Residue ID is G5E. The output is the requested RMSD data as a time series, the RMSD plotted as a time series and as a histogram.

In our case the ligand is stable with a single binding mode. The RMSD fluctuates around 0.3Å, with a slight fluctuation near the end of the simulation. This is more clearly seen in the histogram. The conformation seen during simulation is very similar to that in the crystal structure and the ligand is stable in the active site.
