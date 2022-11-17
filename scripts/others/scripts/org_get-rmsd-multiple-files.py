#!/usr/bin/python3

# Get RMSDs from multiple files 
# INPUTS: input dir and pattern string

USAGE="get-rmsd-multiple-files.py <input dir> <DCD file pattern>"
	
import os, sys

#--------------------------------------------------------------------
# Get RMSDs from trayectory using a VMD script
def getRMSDsFile (psfFile, dcdFile):
	# Get and save RMSDs from namd out file 
	outFile = os.path.basename ("%s_RMSD.dat" % dcdFile.split(".dcd")[0])
	cmm = "xvmd rmsdvmd.tcl %s %s %s" % (psfFile, dcdFile, outFile)
	print (">>> ", cmm)
	os.system (cmm)
	createRMSDTable (outFile)
	return (open (outFile).readlines())
#--------------------------------------------------------------------
# Create CSV table from RMSD values in data file
def createRMSDTable (datFile):
	rmsdValues  = open (datFile).readlines ()
	steps       = [str(x) for x in range (0, len (rmsdValues))]
	stepsRMSDs  = [",".join (x) for x in zip (steps, rmsdValues)]
	csvFilename = "%s.csv" % datFile.split (".dat")[0]
	csvFile     = open (csvFilename, "w")
	csvFile.write ("STEPS,RMSDs\n")
	csvFile.writelines (stepsRMSDs)
	csvFile.close()
#--------------------------------------------------------------------

# Check command line arguments
args = sys.argv 
if (len(args) < 4):
    print (USAGE)
    sys.exit (0)

inputDir = args [1]
psfFile  = args [2]
pattern  = args [3]

# Get files
dcdFiles = ["%s/%s" % (inputDir,x) for x in os.listdir (inputDir) if pattern in x]
dcdFiles.sort()

for f in dcdFiles:
	print (f)

# Get RMSDs for each DCD file
FIRST = True
allRMSDValues = []
for dcdFile in dcdFiles:
	RMSDLines = getRMSDsFile (psfFile, dcdFile)
	allRMSDValues.extend (RMSDLines)

steps      = [str(x) for x in range (0, len (allRMSDValues))]
stepsRMSDs = [",".join (x) for x in zip (steps, allRMSDValues)]
allRMSDsFile = open ("all_RMSDs.csv", "w")
allRMSDsFile.write ("Step,RMSD\n")
allRMSDsFile.writelines (stepsRMSDs)

