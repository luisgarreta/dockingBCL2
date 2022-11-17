#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/opt/miniconda3/envs/prolif/bin/python

USAGE="\
Calculate interaction energies for all poses in input dir\n\
USAGE: interaction-energies-ALL.py <input trajectories dir>"

import os, sys
import multiprocessing as mp

args = sys.argv

inDir   = args [1]
outDir  = "out-ienergies"
PSFFILE	= "step5_input.psf"
DCDFILE	= "step7-DCDs.dcd"
WORKDIR = os.getcwd()

def calculateInterEnergies (dir):
    dirPath = (WORKDIR, inDir, dir)
	psfFile  = [x for x in os.listdir (dirPath) if ".psf" in x][0]
	dcdFile  = [x for x in os.listdir (dirPath) if ".dcd" in x][0]

	inPath  = "%s/%s" % (inDir, dir)
	inPSF   = "%s/%s/%s" % (WORKDIR, inPath, PSFFILE)
	inDCD   = "%s/%s/%s" % (WORKDIR, inPath, DCDFILE)



	# Create and change to out dir and run commands
	outPath = "%s/%s" % (outDir, dir)
	os.system ("mkdir -p %s" % outPath)
	os.chdir (outPath)

	# Calculate
	cmm1 = "interaction-energies.py %s %s" % (inPSF, inDCD)
	print (cmm1)
	os.system (cmm1)
	
dirList = os.listdir (inDir)
pool = mp.Pool (maxtasksperchild=1, processes=3)
pool.map (calculateInterEnergies, dirList)

