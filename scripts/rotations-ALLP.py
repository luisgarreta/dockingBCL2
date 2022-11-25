#!/usr/bin/env python3

USAGE="\
Calculate rotations for all frames in the trajectory\n\
USAGE: rotations-ALLP.py <input trajectory dir> <Output results dir>"
import os, sys
import subprocess as sp
import multiprocessing as mp
from functools import partial

def main ():
	args = sys.argv
	if (len (args) < 2):
		print (USAGE)
		sys.exit(0)

	inputDir   = args [1]	# trajectories
	outputDir  = "out-%s" % inputDir
	outputFile  = "%s/%s.csv" % (outputDir, outputDir)

	if (not os.path.exists (outputFile)):
		print (">>> Calculating rotations..")
		createDir (outputDir)
		dcdsList = ["%s/%s" % (inputDir, x) for x in os.listdir (inputDir) if ".dcd" in x]
		dcdsList = sorted (dcdsList)
		psfFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if ".psf" in x][0])
		pdbFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if "REF.pdb" in x][0])

		## Parallel calculation
		os.system ("mkdir %s" % outputDir)
		pool = mp.Pool (maxtasksperchild=1, processes=3)
		pool.map (partial (calculateRotations, inputDir, psfFile, pdbFile, outputDir), dcdsList) 

		#for dcdFile in dcdsList:
		#	calculateRotations (inputDir, psfFile, pdbFile, outputDir, dcdFile)

		# Collect outputs
		collectOutputs (outputDir, outputFile)

	# Create table in long format and create plot
	cmm2 = "format-wide2long.R %s %s %s %s " % (outputFile, "FRAME", "AXIS", "DEGREES")
	print (">>>", cmm2)
	os.system (cmm2)

	outLongFile = outputFile.replace (".csv", "-LONG.csv")
	if ("Complex" in outLongFile):
		TITLE = "Axis rotations for complex"
	else:	
		TITLE = "Axis rotations for protein"
		
	cmm3 = "plot-XY-MultiLine.R %s %s %s %s '%s' '%s'" % (outLongFile, "FRAME", "DEGREES", "AXIS", TITLE, "FRAME (ns)")
	print (">>>", cmm3)
	os.system (cmm3)

#------------------------------------------------------------------
# calculateRotations
#------------------------------------------------------------------
def calculateRotations (inputDir, psfFile, pdbFile, outputDir, dcdFile):
	outFile = "%s/%s" % (outputDir, os.path.basename (dcdFile.replace (".dcd", ".csv")))
	cmm = "rotations-trajectory.tcl %s %s %s %s" % (psfFile, dcdFile, pdbFile, outFile)
	print (cmm)
	os.system (cmm)

#------------------------------------------------------------------
# Collect outputs
#------------------------------------------------------------------
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

#------------------------------------------------------------------
# Utility to create a directory safely.
#------------------------------------------------------------------
def createDir (dir):
	def checkExistingDir (dir):
		if os.path.lexists (dir):
			headDir, tailDir = os.path.split (dir)
			oldDir = os.path.join (headDir, "old-" + tailDir)
			if os.path.lexists (oldDir):
					checkExistingDir (oldDir)

			os.rename (dir, oldDir)
	checkExistingDir (dir)
	os.system ("mkdir -p %s" % dir)

main ()

