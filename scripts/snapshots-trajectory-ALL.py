#!/usr/bin/env python

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/opt/miniconda3/envs/prolif/bin/python

USAGE="\
Create snapshots for complete trajectory in input dir\n\
USAGE: snapshots-trajectory-ALL.py <input trajectories dir>"

import os, sys
import multiprocessing as mp
from functools import partial

def main ():
	args = sys.argv

	inputDir   = args [1]	# trajectories
	percentage =  args [2]	# trajectories
	outputDir  = "out-snapshots"
	PSFFILE	   = "step5_input.psf"
	DCDFILE	   = "step7-DCDs.dcd"
	WORKINGDIR = os.getcwd()

	# Execute in parallel with multiple arguments
	pool = mp.Pool (maxtasksperchild=1)
	dirList = os.listdir (inputDir)
	#pool.map (partial (createSnapshotsRGB, inputDir, percentage,  outputDir, PSFFILE, DCDFILE, WORKINGDIR), dirList) 
	for dir in dirList:
	    createSnapshotsRGB (inputDir, percentage, outputDir, PSFFILE, DCDFILE, WORKINGDIR, dir) 
	    os.chdir (WORKINGDIR)


#---------------------------------------------------------------------
#---------------------------------------------------------------------
def createSnapshotsRGB (inputDir, percentage, outputDir, PSFFILE, DCDFILE,  WORKINGDIR, dir):
	print (inputDir, outputDir, PSFFILE, DCDFILE,  WORKINGDIR, dir)

	inPath  = "%s/%s" % (inputDir, dir)
	inPSF   = "%s/%s/%s" % (WORKINGDIR, inPath, PSFFILE)
	inDCD   = "%s/%s/%s" % (WORKINGDIR, inPath, DCDFILE)

	# Create and change to out dir and run commands
	outputPath = "%s/%s" % (outputDir, dir)
	os.system ("mkdir -p %s" % outputPath)
	os.chdir (outputPath)

	# Calculate
	cmm1 = "snapshots-trajectory.tcl %s %s %s" % (inPSF, inDCD, percentage)
	print (cmm1)
	os.system (cmm1)
	createSnapshotsPNG (".")
#---------------------------------------------------------------------
#---------------------------------------------------------------------
def createSnapshotsPNG (inputDir):
    cmms = ["convert %s %s.png" % (x, x.split(".")[0]) for x in os.listdir(inputDir)]
    pool = mp.Pool (maxtasksperchild=1)
    pool.map (os.system, cmms)
    #os.system ("rm *.rgb")
#---------------------------------------------------------------------
#---------------------------------------------------------------------
main ()

