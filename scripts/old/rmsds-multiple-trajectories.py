#!/usr/bin/python3

# Get RMSDs from multiple files 
# INPUTS: input dir and pattern string

USAGE="rmsds-multiple-trajectories.py <input dir>"
	
import os, sys

#--------------------------------------------------------------------
# Get RMSDs from trayectory using a VMD script
def getRMSDsFile (psfFile, dcdFile, startTime, outFile=""):
	# Get and save RMSDs from namd out file 
	if (outFile==""):
		outFile = os.path.basename ("%s_RMSD.csv" % dcdFile.split(".dcd")[0])
		prefix   = os.path.basename (dcdFile).split("_")[0]
	else:
		prefix   = os.path.basename (outFile).split(".")[0].split ("-")[-1]

	cmm = "rmsd-trajectory.tcl %s %s %s" % (psfFile, dcdFile, outFile)
	print (">>> ", cmm)
	os.system (cmm)
	#createRMSDTable (outFile)
	values   = open (outFile).readlines()[1:]
	N		= len (values)
	lines	= [",".join (x) for x in zip ([prefix]*N, values)]
	return (lines)
#--------------------------------------------------------------------
# Create CSV table from RMSD values in data file
def createRMSDTable (datFile):
	rmsdValues  = open (datFile).readlines ()
	steps	   = [str(x) for x in range (0, len (rmsdValues))]
	stepsRMSDs  = [",".join (x) for x in zip (steps, rmsdValues)]
	csvFilename = "%s.csv" % datFile.split (".csv")[0]
	csvFile	 = open (csvFilename, "w")
	csvFile.write ("STEPS,RMSDs\n")
	csvFile.writelines (stepsRMSDs)
	csvFile.close()
#--------------------------------------------------------------------

# Check command line arguments
args = sys.argv 
if (len(args) < 2):
	print (USAGE)
	sys.exit (0)

inputDir  = args [1]
outputDir = "rmsds"

# Get RMSDs for each DCD file
allRMSDValues = []
startTime = 1
subDirs = os.listdir (inputDir)
os.system ("mkdir %s" % outputDir)
for subdir in subDirs:
	subdirPath = "%s/%s" % (inputDir, subdir)
	psfFile    = [x for x in os.listdir (subdirPath) if ".psf" in x][0]
	dcdFile    = [x for x in os.listdir (subdirPath) if ".dcd" in x][0]
	psfPath    = "%s/%s" % (subdirPath, psfFile)
	dcdPath    = "%s/%s" % (subdirPath, dcdFile)

	print (">>> ", subdir, psfPath, dcdPath)

	outFile    = "%s/rmsds-%s.csv" % (outputDir,  os.path.basename (subdir))
	rmsds	   = getRMSDsFile (psfPath, dcdPath, startTime, outFile)
	allRMSDValues.extend (rmsds)

#steps	  = [str(x) for x in range (0, len (allRMSDValues))]
#stepsRMSDs = [",".join (x) for x in zip (steps, allRMSDValues)]
outFilename  = "%s/%s-RMSDs.csv" % (outputDir, inputDir)
allRMSDsFile = open (outFilename, "w")
allRMSDsFile.write ("DOCKINGPOSE, TIME, RMSD\n")
allRMSDsFile.writelines (allRMSDValues)

