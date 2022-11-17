#!/usr/bin/env python

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/opt/miniconda3/envs/prolif/bin/python

USAGE="\
Calculate non-bondesi energies for all poses in input dir\n\
USAGE: nonbonded-energies-ALL.py <input trajectories dir>"

import os, sys
import multiprocessing as mp
from functools import partial

def main ():
	args = sys.argv

	inputDir   = args [1]	# trajectories
	paramsDir  = args [2]
	outputDir  = "out-nbenergies"
	PSFFILE	   = "step5_input.psf"
	DCDFILE	   = "step7-DCDs.dcd"
	OUTNAME	   = "nonbonded-energies.csv"
	WORKINGDIR = os.getcwd()

	# Execute in parallel with multiple arguments
	pool    = mp.Pool (maxtasksperchild=1)
	dirList = os.listdir (inputDir)
	params  = [inputDir, outputDir, paramsDir, PSFFILE, DCDFILE, WORKINGDIR]
	pool.map (partial (calculteNonBondedEnergies, inputDir, outputDir, paramsDir, PSFFILE, DCDFILE, WORKINGDIR), dirList) 

	#for dir in dirList:
	#	calculteNonBondedEnergies (inputDir, outputDir, paramsDir, PSFFILE, DCDFILE, WORKINGDIR, dir)
	#	os.chdir (WORKINGDIR)

#---------------------------------------------------------------------
#---------------------------------------------------------------------
def calculteNonBondedEnergies (inputDir, outputDir, paramsDir, PSFFILE, DCDFILE,  WORKINGDIR, dir):
	print (inputDir, outputDir, paramsDir, PSFFILE, DCDFILE,  WORKINGDIR, dir)

	inPath  = "%s/%s" % (inputDir, dir)
	inPSF   = "%s/%s/%s" % (WORKINGDIR, inPath, PSFFILE)
	inDCD   = "%s/%s/%s" % (WORKINGDIR, inPath, DCDFILE)

	# Create and change to out dir and run commands
	outputPath = "%s/%s" % (outputDir, dir)
	os.system ("mkdir -p %s" % outputPath)
	os.chdir (outputPath)

	# Calculate
	cmm1 = "nonbonded-energies-trajectory.tcl %s %s %s" % (inPSF, inDCD, paramsDir)
	print (cmm1)
	os.system (cmm1)
	
	# Plot
	#cmm2 = "interaction-energies-plot.R %s" % "interaction-energies.csv"
	#print (cmm2)
	#os.system (cmm2)
#---------------------------------------------------------------------
#---------------------------------------------------------------------
main ()

