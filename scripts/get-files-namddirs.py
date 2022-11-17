#!/usr/bin/python3
USAGE="\
Get output files from compressed namd results in charmmgui directories.\n\
USAGE: get_outfiles_simulations.py <Ligands dir with namd-confXX.tgz files>"

import os, sys
import glob                   # For listing files with wildcars
import multiprocessing as mp

args      = sys.argv
args      = ["","charmmguis", "namdouts"]
inputDir  = args [1]
outputDir = args [2]

os.system ("mkdir %s" % outputDir)
#namdsDir   = args [1]

filePatterns = ["step7*.dcd", "*.psf", "*.pdb"]
def main ():
    subDirs = os.listdir (inputDir)
    for subdir in subDirs:
        inputNamdPath     = "%s/%s/namd" % (inputDir, subdir)
        filePatternsPaths = ["%s/%s" % (inputNamdPath, x) for x in filePatterns]
        files             = sum (map (glob.glob, filePatternsPaths), [])

        poseName       = subdir.split ("-")[-1]
        outputNamdPath = "%s/namd-%s" % (outputDir, poseName)
        #os.system ("mkdir %s" % outputNamdPath)
        print (outputNamdPath)
        print (files)
