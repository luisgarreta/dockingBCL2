#!/usr/bin/env python3

USAGE="\
Calculate RMSFs for split DCD trajectory\n\
USAGE: rmsfs-ALLP.py <input dir> <output dir>"

import os, sys
import multiprocessing as mp
from functools import partial

def main ():
	args = sys.argv
	if (len (args) < 3):
		print (USAGE)
		sys.exit (0)

	inputDir   = args [1]	# trajectories
	outputDir  = args [2]   # outs
	os.system ("mkdir %s" % outputDir)
	outputFile = "out-RMSFs-%s.csv" % inputDir

	dcdsList = ["%s/%s" % (inputDir, x) for x in os.listdir (inputDir) if ".dcd" in x]
	dcdsList.sort()
	psfFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if ".psf" in x][0])
	pdbFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if "REF.pdb" in x][0])

	# Parallel calculation
	pool = mp.Pool (maxtasksperchild=1, processes=3)
	params   = [inputDir, psfFile]
	pool.map (partial (calculateRMSFs, inputDir, psfFile, pdbFile, outputDir), dcdsList) 

#	for dcdFile in dcdsList:
#		calculateRMSFs (inputDir, psfFile, outputDir, dcdFile)

	# Collect outputs
	collectOutputs (outputDir, outputFile)

	# Create table in long format and create plot
	cmm2 = "wide2long-format.R %s %s %s %s " % (outputFile, "RESID", "SYSTEM", "RMSF")
	print (">>>", cmm2)
	os.system (cmm2)

	outLongFile = outputFile.replace (".csv", "-LONG.csv")
	cmm3 = "plot-XY-MultiLine.R %s %s %s %s '%s' '%s'" % (outLongFile, "RESID", "RMSF", "SYSTEM", "Plot for RMSFs", "RESIDUES")
	print (">>>", cmm3)
	os.system (cmm3)


# Collect outputs
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

def calculateRMSFs (inputDir, psfFile, pdbFile, outputDir, dcdFile):
	outFilename = "%s/rmsf-%s.csv" % (outputDir, os.path.basename (dcdFile).split(".")[0])
	cmm = "rmsfs-trajectory-ref.tcl %s %s %s %s" % (psfFile, dcdFile, pdbFile, outFilename)
	print (cmm)
	os.system (cmm)


main ()

