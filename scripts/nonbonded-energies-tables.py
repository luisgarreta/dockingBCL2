#!/usr/bin/env python

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/usr/bin/python3

# Get RMSDs from multiple files 
# INPUTS: input dir and pattern string

USAGE="nonbonded-energies-tables.py <input dir>"
energiesFile = "nonbonded-energies.csv"
outputFile   = "nonbonded-energies-all-values.csv"
	
import os, sys

def main ():
	# Check command line argument
	args = sys.argv 
	if (len(args) < 2):
		print (USAGE)
		sys.exit (0)

	inputDir   = args [1]

	# Get RMSDs for each DCD file
	allValues = []
	dirList = os.listdir (inputDir)
	for subDir in dirList:
		valuesFile = "%s/%s/%s" % (inputDir, subDir, energiesFile)
		print (">>> ", valuesFile)
		dockingPose = subDir.split ("-")[1]
		values  = createValuesTable (valuesFile, dockingPose)
		allValues.extend (values)

	allValuesFile = open (outputFile, "w")
	allValuesFile.write ("Pose      Frame         Time          Elec          VdW           Nonbond       Total\n")
	allValuesFile.writelines (allValues)

#--------------------------------------------------------------------
# Create CSV table from RMSD values in data file
#--------------------------------------------------------------------
def createValuesTable (valuesFile, dockingPose):
	values       = open (valuesFile).readlines ()[1:]
	subdirValues = ["{:10} {}".format (dockingPose, x) for x in values]
	return (subdirValues)
#--------------------------------------------------------------------
main()


