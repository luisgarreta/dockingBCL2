#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python

# Create table in long format for XY plots from particular tables in dirs

USAGE	   = "\
Create table in long format for XY plots from individual .csv tables (FRAME, VALUE) in dirs\n\
USAGE: create-longtable-fromFiles.py <input dir> [out file]"
	
import os, sys
args = sys.argv 
#args = ["", "outrmsf"]

def main ():
	if (len(args) < 2):
		print (USAGE)
		sys.exit (0)

	INPUTDIR   = args [1]
	OUTFILE	   = "%s-LONG.csv" % INPUTDIR

	# Get RMSDs for each DCD file
	allValues = []
	dirList = [x for x in sorted (os.listdir (INPUTDIR)) if ".csv" in x]
	print ("Files: %s", dirList)
	for i, file in enumerate (dirList):
		valuesPath = "%s/%s" % (INPUTDIR, file)
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


