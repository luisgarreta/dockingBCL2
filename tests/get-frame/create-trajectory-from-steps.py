#!/usr/bin/python3
USAGE="\
Create full trajectory DCD from single step DCDs\n\
Moreover, copy PSF and PDB files along with full DCD trajectory.\n\
USAGE: md-dcd-create-full-trajectory-from-steps.py  <namdouts dir>" 

import os, sys
args = sys.argv

# Specific names according to simulation
PSFFILE    = "step5_input.psf"
PDBFILE    = "step5_input.pdb"
DCDPATTERN = "step7*dcd"

if (len (args) < 2):
    print (USAGE)
    sys.exit (0)

#args = ["", "namdouts","trajectories"]
inputDir   = args [1]  # namdouts
outputDir  = args [2]  # trajectories
workingDir = os.getcwd()

os.system ("mkdir %s" % outputDir)

# Create full DCD file and copy structure file (PSF)
namdsDirs = [x for x in os.listdir (inputDir)]
for namdDir in namdsDirs:
    namdpath      = "%s/%s/%s" % (workingDir, inputDir, namdDir)
    trajectoryDir = "%s/out-%s" % (outputDir, namdDir)

    os.system ("mkdir %s" % trajectoryDir)
    os.chdir (trajectoryDir)

    cmm = "cat-dcd-from-dir-pattern.py %s %s" % (namdpath, "step7")
    print (cmm)
    os.system (cmm)

    # Copy PSF file next to DCD file
    cmm1 = "cp  %s/%s ." % (namdpath, PSFFILE)
    os.system (cmm1)
    cmm2 = "cp  %s/%s ." % (namdpath, PDBFILE)
    os.system (cmm2)

    os.chdir (workingDir)

