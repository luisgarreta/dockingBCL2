#!/usr/bin/env python3
import os,sys

inDir = sys.argv [1]
dirList = os.listdir (inDir)

workingDir = os.getcwd()
for dir in dirList:
    dirPath = "%s/%s" % (inDir, dir)
    print (dirPath)
    os.chdir (dirPath)
    cmm = "filter-residues-interactions.R interaction-energies.csv"
    os.system (cmm)
    os.chdir (workingDir)

