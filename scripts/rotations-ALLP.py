#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/opt/miniconda3/envs/prolif/bin/python

USAGE="\
Calculate rotations for all frames in the trajectory\n\
USAGE: rotations-ALLP.py <input trajectory dir> <Output results dir>"

import os, sys
import subprocess as sp
import multiprocessing as mp
from functools import partial

def main ():
    print "Main..."
	args = sys.argv
	if (len (args) < 3):
		print (USAGE)
		sys.exit(0)

	inputDir   = args [1]	# trajectories
	outputDir  = args [2]   # outs
	plotTitle  = args [3] if len (args > 3) else "Rotation angle plot"
	outputFile = "out-Rotations-%s.csv" % outputDir

	dcdsList = ["%s/%s" % (inputDir, x) for x in os.listdir (inputDir) if ".dcd" in x]
	dcdsList = sorted (dcdsList)
	psfFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if ".psf" in x][0])
	pdbFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if "Frame0-REF.pdb" in x][0])

	## Parallel calculation
	os.system ("mkdir %s" % outputDir)
	pool = mp.Pool (maxtasksperchild=1, processes=3)
	pool.map (partial (calculateRotations, inputDir, psfFile, pdbFile, outputDir), dcdsList) 

	#for dcdFile in dcdsList:
	#	calculateRotations (inputDir, psfFile, pdbFile, outputDir, dcdFile)

	# Collect outputs
	collectOutputs (outputDir, outputFile)

	# Create table in long format and create plot
	cmm2 = "wide2long-format.R %s %s %s %s " % (outputFile, "FRAME", "AXIS", "DEGREES")
	print (">>>", cmm2)
	os.system (cmm2)

	outLongFile = outputFile.replace (".csv", "-LONG.csv")
	cmm3 = "plot-XY-MultiLine.R %s %s %s %s '%s' '%s'" % (outLongFile, "FRAME", "DEGREES", "AXIS", plotTitle, "FRAME (ns)")
	print (">>>", cmm3)
	os.system (cmm3)

def calculateRotations (inputDir, psfFile, pdbFile, outputDir, dcdFile):
	outFile = "%s/%s" % (outputDir, os.path.basename (dcdFile.replace (".dcd", ".csv")))
	cmm = "rotations-trajectory.tcl %s %s %s %s" % (psfFile, dcdFile, pdbFile, outFile)
	print (cmm)
	os.system (cmm)

def collectOutputs (outputDir, outputFile):
	csvsList = [x for x in os.listdir (outputDir) if ".csv" in x]
	csvsList = ["%s/%s" % (outputDir, x) for x in sorted (csvsList)]

	nFrame = 0
	allLines = []
	lastAngle = 0
	for i, csvFile in enumerate (csvsList):
		print (">>> ", csvFile)
		lines = open (csvFile).readlines()
		if (i == 0):
			allLines.append (lines [0])   # Header
		for j, line in enumerate (lines [1:]):
			nFrame +=1
			values   = line.strip().split (",")
			psiAngle = int (float (values[3]))

			# Adjust psiAngle as it ranges from 0, 180
			if (lastAngle > 90 and psiAngle < 0):
				psiAngle = psiAngle % 360
			elif (lastAngle < -90 and psiAngle > 0):
				psiAngle = psiAngle % -360

			lineFrame  = "%s,%s,%s,%s\n" % (nFrame, values[1],values[2],psiAngle)
			allLines.append (lineFrame)
			lastAngle  = psiAngle

	outf = open (outputFile, "w")
	outf.writelines (allLines)
	outf.close()

main ()

