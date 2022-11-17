#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/opt/miniconda3/envs/prolif/bin/python

USAGE="\
Calculate non-bondesi energies for all poses in input dir\n\
USAGE: nonbonded-energies-ALL.py <input trajectories dir>"

import os, sys
import multiprocessing as mp
from functools import partial

def main ():
	args = sys.argv

	inputDir   = args [1]	# trajectories
	outputFile  = "out-rottrans.csv"

	dcdsList = [x for x in os.listdir (inputDir) if ".dcd" in x]
	psfFile = [x for x in os.listdir (inputDir) if ".psf" in x][0]

	# Geom center all : 0.051472365856170654 0.10928455740213394 -0.1705181747674942
	# Geom center frame0
	pool = mp.Pool (maxtasksperchild=1, processes=3)
	params   = [inputDir, psfFile]
	pool.map (partial (calculateRotTrasDCD, inputDir, psfFile, X, Y, Z), dcdsList) 

	#for dcdFile in dcdsList:
	#    calculateRotTrasDCD (inputDir, psfFile, dcdFile)

	csvsList = [x for x in os.listdir (inputDir) if ".csv" in x]
	csvsList = ["%s/%s" % (inputDir, x) for x in sorted (csvsList)]

	nFrame = 0
	allLines = []
	for i, csvFile in enumerate (csvsList):
		print (">>> ", csvFile)
		lines = open (csvFile).readlines()
		if (i == 0):
			allLines.append (lines [0])   # Header
		for j, line in enumerate (lines [1:]):
			nFrame +=1
			formatedLine = line.split (",", 1)[1:][0].strip()
			lineFrame = "%s, %s\n" % (nFrame, formatedLine)
			allLines.append (lineFrame)

	outf = open (outputFile, "w")
	outf.writelines (allLines)
	outf.close()

def calculateRotTrasDCD (inputDir, psfFile, X, Y, Z, dcdFile):
    cmm = "rottrans-trajectory.tcl %s/%s %s/%s %s %s %s" % (inputDir, psfFile, inputDir, dcdFile, X, Y, Z)
    print (cmm)
    os.system (cmm)


main ()

