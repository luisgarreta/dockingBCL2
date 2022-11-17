#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/usr/bin/python3


USAGE="\
Creates snapshots from trajectories DCD files. \
USAGE: mc-dcd-create-trajectory-movies.py <input dir>"

import os, sys
import multiprocessing as mp
from functools import partial

args = sys.argv
args = ["", "trajectories"]
if (len (args) < 2):
    print (USAGE)
    sys.exit (0)

inputDir  = args [1]  # namdouts
workingDir = os.getcwd()
outputDir = "outsnapshots"
#os.system ("mkdir %s" % outputDir)

def createSnapshots (inputDir, workingDir, outputDir, trajdir):
    trajpath = "%s/%s" % (inputDir, trajdir)
    psfFile = [x for x in os.listdir (trajpath) if ".psf" in x][0]
    dcdFile = [x for x in os.listdir (trajpath) if ".dcd" in x][0]
    psfFile = "%s/%s/%s" % (workingDir, trajpath, psfFile)
    dcdFile = "%s/%s/%s" % (workingDir, trajpath, dcdFile)

    ligandPath = "%s/%s" % (outputDir, trajdir)
    os.system ("mkdir -p %s" % ligandPath)
    os.chdir (ligandPath)
    os.system ("snapshots-trajectory.tcl %s %s" % (psfFile, dcdFile))

trajDirs = os.listdir (inputDir)
pool     = mp.Pool (maxtasksperchild=1)
pool.map (partial (createSnapshots, inputDir, workingDir, outputDir), trajDirs)

# Create movies in parallel
#
#trajDirs = os.listdir (inputDir)
#for trajdir in trajDirs:
#    trajpath = "%s/%s" % (inputDir, trajdir)
#    psfFile = [x for x in os.listdir (trajpath) if ".psf" in x][0]
#    dcdFile = [x for x in os.listdir (trajpath) if ".dcd" in x][0]
#    psfFile = "%s/%s/%s" % (workingDir, trajpath, psfFile)
#    dcdFile = "%s/%s/%s" % (workingDir, trajpath, dcdFile)
#
#    ligandPath = "%s/%s" % (outputDir, trajdir)
#    os.system ("mkdir -p %s" % ligandPath)
#    os.chdir (ligandPath)
#    os.system ("snapshots-for-trajectory.tcl %s %s" % (psfFile, dcdFile))
#    #movieName = os.path.basename (trajdir)
#    #os.system ("movie-from-snapshots.py %s ../%s" % ("snapshots", movieName))
#    #os.system ("snapshot-summary-for-trajectory.py %s ../%s" % ("snapshots", movieName))
#
#    os.chdir (workingDir)
#
