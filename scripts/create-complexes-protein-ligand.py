#!/usr/bin/python3
USAGE="\
Create complex protein + ligand for selected ligands poses. \
USAGE: create-complexes-protein-ligand.py <Poses dir> <protein file>"

import os, sys
args = sys.argv
args = ["","poses","protein.pdb"]

posesDir    = args [1]
proteinFile = args [2]
protLines   = open (proteinFile).readlines ()
outputDir   = "charmmguis"

posesFiles = os.listdir ("poses")

for poseFile in posesFiles:
    poseName    =  poseFile.split(".")[0]
    posePath    = "%s/%s" % (posesDir, poseFile)
    complexDir  = "%s/complex_%s" % (outputDir, poseName)
    complexPath = "%s/complex_%s.pdb" % (complexDir, poseName)
    print (">>> ", complexPath)

    poseLines  = open (posePath).readlines()
    for i in range (len (poseLines)):
        if "ATOM" in poseLines[i][0:4]:
            poseLines[i] = poseLines[i][:21] + "L" + poseLines[i][22:]

    os.system ("mkdir -p %s" % complexDir)
    complexFile = open (complexPath, "w")
    complexFile.writelines (protLines)
    complexFile.writelines (poseLines)
    complexFile.close ()

    os.system ("cp %s %s" % (posePath, complexDir)) 
    os.system ("cp %s %s" % (proteinFile, complexDir)) 

