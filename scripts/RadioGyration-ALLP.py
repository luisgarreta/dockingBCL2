#!/usr/bin/env python3

USAGE="\
Calculate radio of gyration for split DCD trajectory\n\
USAGE: RadioGyration-ALLP.py <input dir> <output dir>"

import os, sys
import multiprocessing as mp
from functools import partial
NCPUS = 3

def main ():
	args = sys.argv
	if (len (args) < 2):
		print (USAGE)
		sys.exit (0)

	inputDir   = args [1]   # trajectories
	outputDir  = "out-%s" % inputDir
	outputFile  = "%s/%s.csv" % (outputDir, outputDir)

	if (not os.path.exists (outputFile)):
		print (">>> Calculating RMSFs..")
		createDir (outputDir)
		dcdsList = ["%s/%s" % (inputDir, x) for x in os.listdir (inputDir) if ".dcd" in x]
		dcdsList.sort()
		psfFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if ".psf" in x][0])


		# Parallel calculation
		pool = mp.Pool (maxtasksperchild=1, processes=3)
		params   = [inputDir, psfFile]
		pool.map (partial (calculateRG, inputDir, psfFile, outputDir), dcdsList) 

		#for dcdFile in dcdsList:
		#	calculateRG (inputDir, psfFile, outputDir, dcdFile)

		# Collect outputs
		collectOutputs (outputDir, outputFile)

	# Create table in long format and create plot
	cmm2 = "format-wide2long.R %s %s %s %s " % (outputFile, "FRAME", "SYSTEM", "RADIOG")
	print (">>>", cmm2)
	os.system (cmm2)

	outLongFile = outputFile.replace (".csv", "-LONG.csv")
	cmm3 = "plot-XY-MultiLine.R %s %s %s %s '%s' '%s'" % (outLongFile, "FRAME", "RADIOG", "SYSTEM", "Radius of gyration", "FRAME (ns)")
	print (">>>", cmm3)
	os.system (cmm3)

#------------------------------------------------------------------
# Calculate RMSD
#------------------------------------------------------------------
def calculateRG (inputDir, psfFile, outputDir, dcdFile):
	TYPE = "PROTEIN"
	if ("Groove" in inputDir):
		TYPE = "GROOVE"
	elif ("Head" in inputDir):
		TYPE = "HEAD"
	elif ("noFLD" in inputDir):
		TYPE = "NOFLD"
	elif ("noLOOPs" in inputDir):
		TYPE = "noLOOPs"

	outFilename = "%s/rg-%s.csv" % (outputDir, os.path.basename (dcdFile).split(".")[0])
	cmm = "RadioGyration-Complex.tcl %s %s %s %s" % (psfFile, dcdFile, TYPE, outFilename)
	print (cmm)
	os.system (cmm)


# Collect outputs
def collectOutputs (outputDir, outputFile):
	csvsList = [x for x in os.listdir (outputDir) if ".csv" in x]
	csvsList = ["%s/%s" % (outputDir, x) for x in sorted (csvsList)]

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

