#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python

# Create table in long format for XY plots from particular tables in dirs

USAGE	   = "\
Create table in long format for XY plots from particular tables in dirs\n\
USAGE: create-longtable-generic.py <input dir> <values file> <headers string> <output prefix>"
VALUESFILE = "rmsfs-calfa.csv"
HEADERS	   = "POSE, RESID, RMSF\n"
OUTFILE	= "rmsfs-trajectory.csv"
	
import os, sys
args = sys.argv 
#args = ["", "outrmsf"]

def main ():
	# Check command line argument
	if (len(args) < 2):
		print (USAGE)
		sys.exit (0)

	inputDir   = args [1]
	VALUESFILE = args [2]
	HEADERS	   = args [3]
	OUTFILE	   = args [4]

	# Get RMSDs for each DCD file
	allValues = []
	dirList = os.listdir (inputDir)
	for subDir in dirList:
		valuesPath = "%s/%s/%s" % (inputDir, subDir, VALUESFILE)
		print (">>> ", valuesPath)
		dockingPose = subDir.split ("-")[1]
		values	  = createValuesTable (valuesPath, dockingPose)
		allValues.extend (values)
	
	allValuesFile = open (OUTFILE, "w")
	allValuesFile.write (HEADERS+"\n")
	allValuesFile.writelines (allValues)

#--------------------------------------------------------------------
# Create CSV table from RMSD values in data file
#--------------------------------------------------------------------
def createValuesTable (valuesPath, dockingPose):
	values	   = open (valuesPath).readlines ()[1:]
	valuesPose = ["%s, %s" % (dockingPose, x) for x in values]
	return (valuesPose)
#--------------------------------------------------------------------
main()


