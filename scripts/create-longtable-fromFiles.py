#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python

# Create table in long format for XY plots from particular tables in dirs

USAGE	   = "\
Create table in long format for XY plots from particular .csv tables (FRAME, VALUE) in dirs\n\
USAGE: create-longtable-fromFiles.py <input dir> <out file>"
	
import os, sys
args = sys.argv 
#args = ["", "outrmsf"]

def main ():
	# Check command line argument
	if (len(args) < 3):
		print (USAGE)
		sys.exit (0)

	inputDir   = args [1]
	OUTFILE	   = args [2]

	# Get RMSDs for each DCD file
	allValues = []
	dirList = [x for x in sorted (os.listdir (inputDir)) if ".csv" in x]
	for i, file in enumerate (dirList):
		valuesPath = "%s/%s" % (inputDir, file)
		print (">>> ", valuesPath)
		lines	  = open (valuesPath).readlines ()
		if (i==0):
			HEADERS = "%s, %s" % ("SYSTEM", lines [0])

		typename   = file.split ("-")[-1].split(".")[0]
		valuesType = ["%s, %s" % (typename, x) for x in lines [1:]]
		allValues.extend (valuesType)
	
	allValuesFile = open (OUTFILE, "w")
	allValuesFile.write (HEADERS)
	allValuesFile.writelines (allValues)

#--------------------------------------------------------------------
main()


