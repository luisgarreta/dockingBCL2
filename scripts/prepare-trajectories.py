#!/usr/bin/env python3

USAGE="\
Add last frame to the begining of split trajectories\n\
USAGE: prepare-trajectories.py <trejectories input dir>"


import os, sys
import subprocess 
args = sys.argv
if (len (args) < 2):
    print (USAGE)
    sys.exit()

inputDir = args [1]

dcds = [x for x in sorted (os.listdir (inputDir)) if ".dcd" in x]
dcdsPaths = ["%s/%s" % (inputDir, x) for x in dcds]
psfFile = [x for x in os.listdir (inputDir) if ".psf" in x][0]

for i, dcdFile in enumerate (dcdsPaths):
    preparedName = "%s-Prep.dcd" % dcdFile.split (".")[0]
    print ("")

    result = subprocess.run (["get-numframes.py", dcdFile], capture_output=True, encoding='UTF-8')
    numFrames = result.stdout.strip()

    if (i > 0):
        cmm1 = "catdcd -o %s %s %s" % (preparedName, "last.dcd", dcdFile)
        print (cmm1)
        os.system (cmm1)
    else:
        cmm1 = "cp %s %s" % (dcdFile, preparedName)
        print (cmm1)
        os.system (cmm1)

    cmm2  = "catdcd -o %s -first %s -last %s %s" % ("last.dcd", numFrames, numFrames, dcdFile)
    print (cmm2)
    os.system (cmm2)
    #a = input (">>> Next")
    #cmm = "catdcd -o %s -first 1 -last 1"
