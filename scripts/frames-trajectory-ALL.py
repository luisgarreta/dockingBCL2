#!/usr/bin/env python
#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/usr/bin/python
"Create frames with protein and ligand from trajectory"

import os, sys
import multiprocessing as mp
from functools import partial

args = sys.argv
args = ["", "trajectories"]
if (len (args) < 2):
	print (USAGE)
	sys.exit (0)

inputDir  = args [1]  # trajectories
workingDir = os.getcwd()
outputDir = "out-frames"
os.system ("mkdir %s" % outputDir)

#-------------------------------------------------------------
# Create frames function
#-------------------------------------------------------------
def createFramesTrajectory (inputDir, workingDir, outputDir, trajdir):
	trajpath = "%s/%s" % (inputDir, trajdir)
	psfFile  = [x for x in os.listdir (trajpath) if ".psf" in x][0]
	dcdFile  = [x for x in os.listdir (trajpath) if ".dcd" in x][0]
	psfFile  = "%s/%s/%s" % (workingDir, trajpath, psfFile)
	dcdFile  = "%s/%s/%s" % (workingDir, trajpath, dcdFile)

	ligandPath = "%s/%s" % (outputDir, trajdir)
	os.system ("mkdir -p %s" % ligandPath)
	os.chdir (ligandPath)
	os.system ("frames-trajectory.tcl %s %s" % (psfFile, dcdFile))
	os.chdir (workingDir)

#-------------------------------------------------------------
# Create frames in parallel
#-------------------------------------------------------------
trajDirs = os.listdir (inputDir)
pool     = mp.Pool (maxtasksperchild=1)
params   = [inputDir, workingDir, outputDir]
pool.map (partial (createFramesTrajectory, inputDir, workingDir, outputDir), trajDirs) 

#trajDirs = os.listdir (inputDir)
#for trajdir in trajDirs:
#	trajpath = "%s/%s" % (inputDir, trajdir)
#	psfFile  = [x for x in os.listdir (trajpath) if ".psf" in x][0]
#	dcdFile  = [x for x in os.listdir (trajpath) if ".dcd" in x][0]
#	psfFile  = "%s/%s/%s" % (workingDir, trajpath, psfFile)
#	dcdFile  = "%s/%s/%s" % (workingDir, trajpath, dcdFile)
#
#	ligandPath = "%s/%s" % (outputDir, trajdir)
#	os.system ("mkdir -p %s" % ligandPath)
#	os.chdir (ligandPath)
#	os.system ("md-dcd-get-AllFrames-ProteinLigand.tcl %s %s" % (psfFile, dcdFile))
#	os.chdir (workingDir)
#
