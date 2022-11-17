#!/usr/bin/env python3

# Create table in long format from simple CSVs ("FRAME" "VALUE") files in output dir

USAGE	   = "\
Create table in long format from simple CSVs ('FRAME' 'VALUE') files in output dir\n\
USAGE: longtable-fromFiles.py <input dir>"
	
import os, sys
args = sys.argv 

def main ():
	# Check command line argument
	if (len(args) < 2):
		print (USAGE)
		sys.exit (0)

	inputDir = args [1]
	outFile  = "out-rmsds-long.csv"

	filePaths = ["%s/%s" % (inputDir, x) for x in os.listdir (inputDir)]
	print (filePaths)

	newLines = []
	for i,f in enumerate (filePaths):
		typeName = f.split ("-")[-1].split(".")[0]
		if (i==0):
			newLines.append ("%s,%s,%s\n" % ("TYPE", "FRAME", "RMSD"))

		print (typeName)
		lines  = open (f).readlines()[1:]
		flines = ["%s,%s" % (typeName, x) for x in lines]
		newLines.extend (flines)
	
	open (outFile, "w").writelines (newLines)


main ()
