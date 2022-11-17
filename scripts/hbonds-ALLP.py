#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/opt/miniconda3/envs/prolif/bin/python

USAGE="\
Calculate hydrogen bonds for all poses in input dir\n\
USAGE: hbonds-ALL.py <input dir> <output dir>"

import os, sys
import multiprocessing as mp
from functools import partial

def main ():
	args = sys.argv
	if (len (args) < 3):
		print (USAGE)
		sys.exit (0)

	inputDir   = args [1]	# trajectory
	outputDir  = args [2]	# outs
	outputFile = "out-HBONDS-%s.csv" % inputDir

	if (not os.path.exists (outputFile)):
		#os.system ("mkdir %s" % outputDir)
		createDir (outputDir)
		dcdsList = ["%s/%s" % (inputDir, x) for x in os.listdir (inputDir) if ".dcd" in x]
		dcdsList.sort()
		psfFile  = "%s/%s" % (inputDir, [x for x in os.listdir (inputDir) if ".psf" in x][0])

		# Parallel calculation
		pool = mp.Pool (maxtasksperchild=1, processes=3)
		params	 = [inputDir, psfFile]
		pool.map (partial (calculateHBonds, inputDir, psfFile, outputDir), dcdsList) 

		#	for dcdFile in dcdsList:
		#		calculateHBonds (inputDir, psfFile, outputDir, dcdFile)

	# Collect outputs
	collectOutputs (outputDir, outputFile)

	# Create table in long format and create plot
	#cmm2 = "wide2long-format.R %s %s %s %s " % (outputFile, "FRAME", "SYSTEM", "HBONDS")
	cmm2 = "format-wide2long.R %s %s %s %s " % (outputFile, "FRAME", "SYSTEM", "HBONDS")
	print (">>>", cmm2)
	os.system (cmm2)

	outLongFile = outputFile.replace (".csv", "-LONG.csv")
	cmm3 = "plot-XY-MultiLine.R %s %s %s %s '%s' '%s'" % (outLongFile, "FRAME", "HBONDS", "SYSTEM", "Number of hydrogen bonds", "FRAME (ns)")
	print (">>>", cmm3)
	os.system (cmm3)


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

def calculateHBonds (inputDir, psfFile, outputDir, dcdFile):
	outFilename = "%s/rg-%s.csv" % (outputDir, os.path.basename (dcdFile).split(".")[0])
	cmm = "hbonds-trajectory.tcl %s %s %s" % (psfFile, dcdFile, outFilename)
	print (cmm)
	os.system (cmm)

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

