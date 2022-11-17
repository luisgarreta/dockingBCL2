#!/usr/bin/python3
USAGE="\
Get output files from simulations in charmmgui directories.\n\
USAGE: get-trajectory-files.py <charmmgui dir> <output dir>"

import os, sys
import glob                   # For listing files with wildcars
import multiprocessing as mp

args      = sys.argv
#args      = ["","charmmguis", "namdouts"]
inputDir  = args [1]
outputDir = args [2]

# Check if output dir exists
if (os.path.exists (outputDir)):
    print ("Error: Output dir exists!!")
    sys.exit (0)

os.system ("mkdir %s" % outputDir)
#namdsDir   = args [1]

filePatterns = ["step7_*.dcd", "*.psf", "*.pdb"]
subDirs = os.listdir (inputDir)
workingDir = os.getcwd()
for subdir in subDirs:
    inputNamdPath     = "%s/%s/namd" % (inputDir, subdir)
    filePatternsPaths = ["%s/%s" % (inputNamdPath, x) for x in filePatterns]
    files             = sum (map (glob.glob, filePatternsPaths), [])

    poseName       = subdir.split ("-")[-1]
    outputNamdPath = "%s/namd-%s" % (outputDir, poseName)
    print (">>>")

    cmm1 = "mkdir %s" % outputNamdPath
    print (cmm1)
    os.system (cmm1)

    #cmm2 =  "cp %s %s" % (" ".join (files), outputNamdPath)
    #print (cmm2)
    #os.system (cmm2)

    for filepath in files:
        filename = os.path.basename (filepath)
        #cmm3 = "cp %s/%s %s/%s/%s" % (workingDir, filepath, workingDir, outputNamdPath, filename)  
        cmm3 = "ln -s %s/%s %s/%s/%s" % (workingDir, filepath, workingDir, outputNamdPath, filename)  
        print (cmm3)
        os.system (cmm3)



    #os.system ("c %s" % outputNamdPath)
