#!/usr/bin/env python

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/usr/bin/python3

# Get RMSDs from multiple files 
# INPUTS: input dir and pattern string

USAGE="rmsds-trajectory-ALL.py <input dir>"
	
import os, sys

def main ():
	# Check command line arguments
	args = sys.argv 
	if (len(args) < 2):
		print (USAGE)
		sys.exit (0)

	inputDir  = args [1] # trajectories
	outputDir = "out-rmsds"

	# Get RMSDs for each DCD file
	allRMSDValuesProtein = []
	allRMSDValuesLigand = []
	startTime = 1
	subDirs = os.listdir (inputDir)
	os.system ("mkdir %s" % outputDir)
	for subdir in subDirs:
		subdirPath = "%s/%s" % (inputDir, subdir)
		psfFile	= [x for x in os.listdir (subdirPath) if ".psf" in x][0]
		dcdFile	= [x for x in os.listdir (subdirPath) if ".dcd" in x][0]
		psfPath	= "%s/%s" % (subdirPath, psfFile)
		dcdPath	= "%s/%s" % (subdirPath, dcdFile)

		print (">>> ", subdir, psfPath, dcdPath)

		outFile	= "%s/rmsds-protein-%s.csv" % (outputDir,  os.path.basename (subdir))
		rmsdsProtein  = getRMSDsFile (psfPath, dcdPath, startTime, "protein", outFile)
		outFilename   = "%s/RMSDs-protein-%s.csv" % (outputDir, subdir)
		writeRMSDsToFile (rmsdsProtein, outFilename)

		outFile	= "%s/rmsds-ligand-%s.csv" % (outputDir,  os.path.basename (subdir))
		rmsdsLigand   = getRMSDsFile (psfPath, dcdPath, startTime, "ligand", outFile)
		outFilename   = "%s/RMSDs-%s-ligand.csv" % (outputDir, subdir)
		writeRMSDsToFile (rmsdsLigand, outFilename)

		allRMSDValuesProtein.extend (rmsdsProtein)
		allRMSDValuesLigand.extend (rmsdsLigand)

	allRMSDValues = allRMSDValuesProtein
	allRMSDValues.extend (allRMSDValuesLigand)

	outFilename  = "%s/RMSDs-%s.csv" % (outputDir, inputDir)
	writeRMSDsToFile (allRMSDValues, outFilename)
	#allRMSDsFile = open (outFilename, "w")
	#allRMSDsFile.write ("POSE, FRAME, TYPE, RMSD\n")
	#allRMSDsFile.writelines (allRMSDValues)


#--------------------------------------------------------------------
#--------------------------------------------------------------------
def writeRMSDsToFile (rmsds, outFilename):
	allRMSDsFile = open (outFilename, "w")
	allRMSDsFile.write ("POSE, FRAME, TYPE, RMSD\n")
	allRMSDsFile.writelines (rmsds)
	allRMSDsFile.close()



#--------------------------------------------------------------------
# Get RMSDs from trayectory using a VMD script
def getRMSDsFile (psfFile, dcdFile, startTime, rmsdType, outFile=""):
	# Get and save RMSDs from namd out file 
	if (outFile==""):
		outFile = os.path.basename ("%s_RMSD.csv" % dcdFile.split(".dcd")[0])
		prefix   = os.path.basename (dcdFile).split("_")[0]
	else:
		prefix   = os.path.basename (outFile).split(".")[0].split ("-")[-1]

	cmm = ""
	if (rmsdType=="protein"):
		cmm = "rmsds-trajectory-protein.tcl %s %s %s" % (psfFile, dcdFile, outFile)
	elif (rmsdType=="ligand"):
		cmm = "rmsds-trajectory-ligand.tcl %s %s %s" % (psfFile, dcdFile, outFile)

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
main()
