#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/usr/bin/python
"Create frames with protein and ligand from trajectory"

import os, sys
args = sys.argv
args = ["", "trajectories"]
if (len (args) < 2):
    print (USAGE)
    sys.exit (0)

trajectoriesDir  = args [1]  # namdouts
workingDir = os.getcwd()
outputDir = "frames"
os.system ("mkdir %s" % outputDir)

# Create frames
trajDirs = os.listdir (trajectoriesDir)
for trajdir in trajDirs:
    trajpath = "%s/%s" % (trajectoriesDir, trajdir)
    psfFile  = [x for x in os.listdir (trajpath) if ".psf" in x][0]
    dcdFile  = [x for x in os.listdir (trajpath) if ".dcd" in x][0]
    psfFile  = "%s/%s/%s" % (workingDir, trajpath, psfFile)
    dcdFile  = "%s/%s/%s" % (workingDir, trajpath, dcdFile)

    ligandPath = "%s/%s" % (outputDir, trajdir)
    os.system ("mkdir -p %s" % ligandPath)
    os.chdir (ligandPath)
    os.system ("md-dcd-get-AllFrames-ProteinLigand.tcl %s %s" % (psfFile, dcdFile))
    os.chdir (workingDir)
