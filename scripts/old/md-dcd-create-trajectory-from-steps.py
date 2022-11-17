#!/usr/bin/python3
USAGE="\
Create full trajectory DCD from single step DCDs\n\
Moreover, copy PSF and PDB files along with full DCD trajectory.\n\
USAGE: md-dcd-create-full-trajectory-from-steps.py  <namdouts dir>" 

import os, sys
args = sys.argv
args = ["", "namdouts","trajectories"]

# Specific names according to simulation
PSFFILE    = "step5_input.psf"
PDBFILE    = "step5_input.pdb"
DCDPATTERN = "step7*dcd"

if (len (args) < 2):
    print (USAGE)
    sys.exit (0)

inputDir  = args [1]  # namdouts
outputDir = args [2]

workingDir = os.getcwd()
os.system ("mkdir %s" % outputDir)

# Create full DCD file and copy structure file (PSF)
namdsDirs = [x for x in os.listdir (inputDir)]
for namdDir in namdsDirs:
    namdpath   = "%s/%s/%s" % (workingDir, inputDir, namdDir)
    outNandDir = "out-%s" % namdDir
    os.system ("mkdir %s" % outNandDir)
    os.chdir (outNandDir)
    os.system ("mkdir inputs")
    os.system ("ln -s %s/%s inputs" % (PSFFILE, namdpath))
    os.system ("ln -s %s/step7*dcd inputs" % namdpath)

    cmm = "cat-dcd-from-dir-pattern.py %s %s" % ("inputs", "step7")
    print (cmm)
    os.system (cmm)

    # Copy PSF file next to DCD file
    os.system ("ln -s %s/step5_input.psf" % namdpath)
    os.chdir (workingDir)
    os.system ("mv %s %s" % (outNandDir, outputDir))
