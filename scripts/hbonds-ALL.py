#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/opt/miniconda3/envs/prolif/bin/python

USAGE="\
Calculate hydrogen bonds for all poses in input dir\n\
USAGE: hbonds-ALL.py <input trajectories dir>"

import os, sys
import multiprocessing as mp
from functools import partial

def main ():
	args = sys.argv

	inputDir   = args [1]	# trajectories
	outputDir  = "out-hbonds"
	PSFFILE	   = "step5_input.psf"
	DCDFILE	   = "step7-DCDs.dcd"
	OUTFILE	   = "hbonds-trajectories.csv"
	WORKINGDIR = os.getcwd()

	# Execute in parallel with multiple arguments
	pool = mp.Pool (maxtasksperchild=1)
	dirList = os.listdir (inputDir)
	pool.map (partial (calculateHBONDS, inputDir, outputDir, PSFFILE, DCDFILE, WORKINGDIR), dirList) 
#	for dir in dirList:
#	    calculateHBONDS (inputDir, outputDir, PSFFILE, DCDFILE, WORKINGDIR, dir) 
#	    os.chdir (WORKINGDIR)
#	    break


#---------------------------------------------------------------------
#---------------------------------------------------------------------
def calculateHBONDS (inputDir, outputDir, PSFFILE, DCDFILE,  WORKINGDIR, dir):
	print (inputDir, outputDir, PSFFILE, DCDFILE,  WORKINGDIR, dir)

	inPath  = "%s/%s" % (inputDir, dir)
	inPSF   = "%s/%s/%s" % (WORKINGDIR, inPath, PSFFILE)
	inDCD   = "%s/%s/%s" % (WORKINGDIR, inPath, DCDFILE)

	# Create and change to out dir and run commands
	outputPath = "%s/%s" % (outputDir, dir)
	os.system ("mkdir -p %s" % outputPath)
	os.chdir (outputPath)

	# Calculate
	cmm1 = "hbonds-trajectory.tcl %s %s" % (inPSF, inDCD)
	print (">>>>>>>>>> WkDir: %s Dir: %s" % (os.getcwd(), dir))
	print (cmm1)
	os.system (cmm1)
#---------------------------------------------------------------------
#---------------------------------------------------------------------
main ()

