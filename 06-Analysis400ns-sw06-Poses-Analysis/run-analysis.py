#!/usr/bin/env python3

import os,sys

args = sys.argv

analysisFile = args [1]

analysisList = open (analysisFile).readlines()
WORKINGDIR = os.getcwd ()
for adir in analysisList:
    if ("#" in adir):
        continue
    adir = adir.strip()
    os.chdir (adir)

    os.system ("run.sh")
    os.chdir (WORKINGDIR)



