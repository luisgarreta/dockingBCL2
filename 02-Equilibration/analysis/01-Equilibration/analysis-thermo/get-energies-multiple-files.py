#!/usr/bin/python3

# Get energies from multiple files 
# INPUTS: input dir and pattern string
USAGE="get-energies-multiple-files.py <input dir> <files pattern>"
    
import os, sys

#------------------------------------------------------
# Get and save energies from namd out file 
def getEnergiesFile (energyFile):
	lines = open (energyFile).readlines()
	energyLines = []

	FIRST = True
	for l in lines:
		lst = l.split()
		if (lst==[]):
			continue

		csvLine = ",".join(lst[1:]) + "\n"
		if (lst[0]=="ETITLE:" and FIRST==True): 
			FIRST = False
			energyLines.append (csvLine)

		if (lst[0]=="ENERGY:"):
			energyLines.append (csvLine)

	return (energyLines)
#------------------------------------------------------
# Main
#------------------------------------------------------
import re

args = sys.argv 

inputDir = args [1]
pattern  = args [2]

if (len (args) <  3):
    print (USAGE)
    sys.exit(0)

#inputDir = "namd"
#pattern  = '(step7.*out)'

allFiles    = os.listdir (inputDir)
regex       = re.compile (pattern)

energyFiles = ["%s/%s" % (inputDir,x) for x in allFiles if regex.match (x) ]

energyFiles  = sorted (energyFiles, key=lambda x: int (x.split("_")[1].split(".")[0]))

print ("Energy files in dir %s" % inputDir)
for f in energyFiles:
    print (f)

allEnergiesFile = open ("energies-all-files.csv", "w")
FIRST = True
for f in energyFiles:
	energyLines = getEnergiesFile (f)
	if (FIRST):
		allEnergiesFile.writelines (energyLines)
		FIRST = False
	else:
		allEnergiesFile.writelines (energyLines[1:])

allEnergiesFile.close()
