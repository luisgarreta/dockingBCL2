#!/usr/bin/env python3

USAGE="\
Calculate RMSFs for split DCD trajectory\n\
USAGE: rmsfs-ALLP.py <input dir>"

import os, sys
import multiprocessing as mp
from functools import partial
NCPUS = 4

def main ():
	args = sys.argv
	if (len (args) < 2):
		print (USAGE)
		sys.exit (0)

	inputDir   = args [1]	# trajectories
	outputDir  = "out-%s" % inputDir
	outputFile  = "%s/%s.csv" % (outputDir, outputDir)

	if (not os.path.exists (outputFile)):
		print (">>> Calculating RMSFs..")
		createDir (outputDir)
		dcdsList = ["%s/%s" % (inputDir, x) for x in os.listdir (inputDir) if ".dcd" in x]
		dcdsList.sort()
		psfFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if ".psf" in x][0])
		pdbFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if "REF.pdb" in x][0])

		# Parallel calculation
		pool = mp.Pool (maxtasksperchild=1, processes=NCPUS)
		params   = [inputDir, psfFile]
		pool.map (partial (calculateRMSFs, inputDir, psfFile, pdbFile, outputDir), dcdsList) 

		#for dcdFile in dcdsList:
			#calculateRMSFs (inputDir, psfFile, pdbFile, outputDir, dcdFile)

		# Collect outputs
		collectOutputs (outputDir, outputFile)

	# Create table in long format and create plot
	cmm2 = "format-wide2long.R %s %s %s %s " % (outputFile, "RESID", "SYSTEM", "RMSF")
	print (">>>", cmm2)
	os.system (cmm2)

	outLongFile = outputFile.replace (".csv", "-LONG.csv")
	cmm3 = "plot-XY-MultiLine.R %s %s %s %s '%s' '%s'" % (outLongFile, "RESID", "RMSF", "SYSTEM", "Plot for RMSFs", "RESIDUES")
	print (">>>", cmm3)
	os.system (cmm3)

#------------------------------------------------------------------
# Calculate RMSF
#------------------------------------------------------------------
def calculateRMSFs (inputDir, psfFile, pdbFile, outputDir, dcdFile):
	TYPE = "PROTEIN"
	if ("Groove" in inputDir):
		TYPE = "GROOVE"
	elif ("Head" in inputDir):
		TYPE = "HEAD"

	outFilename = "%s/rmsf-%s.csv" % (outputDir, os.path.basename (dcdFile).split(".")[0])
	cmm = "rmsfs-trajectory-ref.tcl %s %s %s %s %s" % (psfFile, dcdFile, pdbFile, TYPE, outFilename)
	print (cmm)
	os.system (cmm)

#------------------------------------------------------------------
# Collect outputs
#------------------------------------------------------------------
def collectOutputs (outputDir, outputFile):
	csvsList = [x for x in os.listdir (outputDir) if ".csv" in x]
	csvsList = ["%s/%s" % (outputDir, x) for x in sorted (csvsList)]

	allValues = []
	for i, csvFile in enumerate (csvsList):
		print (">>> ", csvFile)
		lines = open (csvFile).readlines()
		if (i == 0):
			allValues = [-1 for x in lines[1:]]
			n = len (allValues)
		for j, line in enumerate (lines [1:]):
			formatedLine = line.strip().split (",")
			resid		=  formatedLine [0]
			value		=  float (formatedLine [1])
			if (allValues [j] == -1):
				allValues [j] = value
			else:
				allValues [j] = (allValues [j] + value)/2


	# Write to file all values
	outf = open (outputFile, "w")
	outf.write ("RESID, RMSF\n")
	for i in range (n):  
		outf.write ("%s, %s\n" % (i+1, allValues [i]))
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

