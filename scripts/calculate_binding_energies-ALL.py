#!/usr/bin/python3
USAGE="\
Calculates protein-ligand binding energy from a set of ligands. \n\
USAGE: calculate_binding_energies.py <Protein pdbqt file> <ligands dir>"

import os, sys
import multiprocessing as mp
#-----------
# Main
#-----------
args = sys.argv
#args = ["","frames"]

if (len (args) < 2):
	print (USAGE)
	sys.exit (0)

#----------------------------------------------------------------------
# Main
#----------------------------------------------------------------------
def main ():
	trajectoriesDirs = args [1]
	outputDir	= "out-BindingEnergies"
	os.mkdir (outputDir)
	workingDir = os.getcwd()

# Create configuration files for autodock4 and vina
# and calculate free binding energies
	trajDirs = os.listdir (trajectoriesDirs)

	for trajdir in trajDirs:
		trajpath  = "%s/%s/%s" % (workingDir, trajectoriesDirs, trajdir)
		outPath   = "%s/%s/%s" % (workingDir, outputDir, trajdir)

		os.chdir (outputDir)
		os.mkdir (os.path.basename (outPath))
		os.chdir (os.path.basename (outPath))

		framesDirs = ["%s/%s" % (trajpath, x) for x in os.listdir (trajpath)]
	
		pool1 = mp.Pool (maxtasksperchild=1)
		pool1.map (createConfigFiles, framesDirs)

		os.chdir (workingDir)

#----------------------------------------------------------------------
# Calculate Free Binding Energy for a ligand creating its own dir
#----------------------------------------------------------------------
def createConfigFiles (frameDir):
	frameName = os.path.basename (frameDir)
	curDir = os.getcwd()
	os.mkdir (os.path.basename (frameDir))
	os.chdir (os.path.basename (frameDir))

	os.system ("ln -s %s/%s-protein.pdb protein.pdb" %  (frameDir, frameName)) 
	os.system ("ln -s %s/%s-ligand.pdb ligand.pdb" % (frameDir, frameName))

	#1) Preparing a protein
	os.system ("prepare_receptor4.py -r protein.pdb") 
	#2) Preparing a ligand
	os.system ("prepare_ligand4.py -l ligand.pdb")
	#3) Generating a grid parameter file
	os.system ("prepare_gpf4.py -l ligand.pdbqt -r protein.pdbqt -y")
	#4) Generating maps and grid data files
	os.system ("autogrid4 -p protein.gpf")
	#5) Generating a docking parameter file
	os.system ("prepare_dpf4.py -l ligand.pdbqt -r protein.pdbqt")
	
	#6) Create config files
	createAutodockConfigFile ()
	createVinaConfigFile ("protein.gpf")

	#7) Running AutoDock
	os.system ("autodock4 -p config_autodock.dpf -l out_energies_autodock.log")
	#8) Running Vina
	os.system ("vina --config config_vina.config --score_only > out_energies_vina.log")

	os.chdir (curDir)

#----------------------------------------------------------------------
#----------------------------------------------------------------------
def createAutodockConfigFile ():
	#6) Modifying docking parameters file
	with open ("ligand_protein.dpf") as parFile:
		parLines = parFile.readlines()[0:14]
	parLines.append ("epdb							# **add** this to evaluate the small molecule")
	with open ("config_autodock.dpf", "w") as parFile:
		parFile.writelines(parLines)

	return ("config_autodock.dpf")

#----------------------------------------------------------------------
#----------------------------------------------------------------------
def createVinaConfigFile (gridParamsFile):
	gridLines = open (gridParamsFile).readlines ()
	for line in gridLines:
		if ("npts" in line):
			elems = line.split()
			sizeX,sizeY,sizeZ = elems[1], elems[2], elems [3]
		elif ("gridcenter" in line):
			elems = line.split()
			centerX,centerY,centerZ = elems[1], elems[2], elems [3]
	
	with open ("config_vina.config", "w") as vf:
		vf.write ("receptor = protein.pdbqt\n")
		vf.write ("ligand   = ligand.pdbqt\n")
		vf.write ("center_x = %s  # Center of Grid points X\n" % centerX)
		vf.write ("center_y = %s  # Center of Grid points Y\n" % centerY)
		vf.write ("center_z = %s  # Center of Grid points Z\n" % centerZ)
		vf.write ("size_x   = %s  # Number of Grid points in X direction\n" % sizeX)
		vf.write ("size_y   = %s  # Number of Grid points in Y Direction\n" % sizeY)
		vf.write ("size_z   = %s  # Number of Grid points in Z Direction\n" % sizeZ)

	return ("config_vina.config")

#----------------------------------------------------------------------
# Main
#----------------------------------------------------------------------
main ()
