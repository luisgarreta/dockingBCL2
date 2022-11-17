#!/usr/bin/python3
import os, sys

args = sys.argv

inputDir   = "dcds"
outDCDFile = "production_20ns_trajectory.dcd"

dcdFiles = ["%s/%s"%(inputDir,x) for x in os.listdir (inputDir) if ".dcd" in x and not "equilibration" in x]
dcdFiles = sorted (dcdFiles, key=lambda x: int (x.split("_")[1].split(".")[0]))

for dcd in dcdFiles:
    print (dcd)

cmm = "catdcd -o %s %s" % (outDCDFile, " ".join (dcdFiles))
print (cmm)
os.system (cmm)
        
