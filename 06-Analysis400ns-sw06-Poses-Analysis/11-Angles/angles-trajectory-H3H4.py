#!/usr/bin/env python3

# Calculate the angles between helices H3 and H4 in the full trajectory
# It uses a pymol plugin "angles-trajectory-H3H4.py"

import multiprocessing as mp
from pymol import cmd
import anglebetweenhelices as ang
import os, sys

args = sys.argv

inputDir = args [1]
outFile  = "angles-trajectory-H3H4.csv"

namdsDirsList = ["%s/%s" % (inputDir, x) for x in  os.listdir (inputDir)]
print (">>>", namdsDirsList)

#--------------------------------------------------------------
def dummy (frameDir):
    return ("1,1")
#--------------------------------------------------------------
def calculateHelicesAngle (frameDir):
    files = os.listdir (frameDir)
    proteinFile = [x for x in files if "protein" in x][0]
    proteinFile ="%s/%s" % (frameDir, proteinFile)

    #print (frameDir)
    #print (proteinFile)
    # load PDBs
    cmd.load (proteinFile, "f")

    # Select helices
    cmd.select ("h3", "resid 105-112")
    cmd.select ("h4", "resid 120-131")

    # Set color to helices
    #cmd.color ("red", "h3")
    #cmd.color ("blue", "h4")

    # just calculate/visualize orientation of single alpha-helix
    #ang.helix_orientation_hbond ("h3")
    #ang.helix_orientation_hbond ("h4")

    # Get angle between two helices
    res = ang.angle_between_helices ("h3", "h4")
    frameNumber = os.path.basename (frameDir).split("frame")[1]
    resString = "%s, %s, %s" % ("sw06", int (frameNumber), res)

    return (resString)
#--------------------------------------------------------------
results = list ()
for namdDir in namdsDirsList:
    framesDirList = ["%s/%s" % (namdDir, x) for x in  os.listdir (namdDir)]
    framesDirList.sort()
    pool    = mp.Pool (maxtasksperchild=1)
    results = pool.map (calculateHelicesAngle, framesDirList)
    #for i, frameDir in enumerate (framesDirList):
    #    res = calculateHelicesAngle (frameDir)
    #    results.append (res)


anglesFile = open (outFile, "w")
anglesFile.write ("POSE, FRAME, ANGLE\n")
anglesFile.writelines ("\n".join (results))
