#!/usr/bin/python3
USAGE="\
Calculates protein-ligand binding energy from a set of ligands. \n\
USAGE: calculate_binding_energies.py <Protein pdbqt file> <ligands dir>"

import os, sys
#-----------
# Main
#-----------
args = sys.argv
if (len (args) < 2):
	print (USAGE)
	sys.exit (0)

# Default params
args [1] = "protein.pdbqt"
args [2] = "ligands"
#----------------------------------------------------------------------
# Main
#----------------------------------------------------------------------
def main ():
	protein	      = args [1]
	allLigandsDir = args [2]

	allLigands = os.listdir (allLigandsDir)
	for ligandFile in allLigands:
		dirLigand  = ligandFile.split ("_")[0].replace ("conf", "conformation")
		os.system ("mkdir %s" % dirLigand)
		os.chdir (dirLigand)

		configFiles = createConfigFiles (protein, ligandFile, allLigandsDir)
		calculateBindingEnergies (configFiles)

		os.chdir ("..")

	os.mkdir ("energies")
	os.system ("mv conformation* energies")

#----------------------------------------------------------------------
#----------------------------------------------------------------------
def calculateBindingEnergies (configFiles):
	autodockConfigFile = configFiles [0]
	vinaConfigFile     = configFiles [1]

	#7) Running AutoDock
	os.system ("autodock4 -p %s -l out_energies_autodock.log" % autodockConfigFile)
	os.system ("vina --config %s --score_only > out_energies_vina.log" % vinaConfigFile)

#----------------------------------------------------------------------
# Calculate Free Binding Energy for a ligand creating its own dir
#----------------------------------------------------------------------
def createConfigFiles (proteinFile, ligandFile, allLigandsDir):
	print (">>>", ligandFile)
	ligandName = ligandFile.split (".")[0]

	os.system ("ln -s ../protein.pdbqt")
	os.system ("ln -s ../%s/%s ligand.pdb" % (allLigandsDir, ligandFile))
	open ("ligand.name", "w").write (ligandName.split("_")[1])

	#1) Preparing a protein
	#prepare_receptor4.py -r protein.pdb 
	#2) Preparing a ligand
	os.system ("prepare_ligand4.py -l ligand.pdb")
	#3) Generating a grid parameter file
	os.system ("prepare_gpf4.py -l ligand.pdbqt -r protein.pdbqt -y")
	#4) Generating maps and grid data files
	os.system ("autogrid4 -p protein.gpf")
	#5) Generating a docking parameter file
	os.system ("prepare_dpf4.py -l ligand.pdbqt -r protein.pdbqt")
	
	autodockConfigFile = createAutodockConfigFile ()
	vinaConfigFile     = createVinaConfigFile ("protein.gpf")
	configFiles = [autodockConfigFile, vinaConfigFile]
	return (configFiles)


#----------------------------------------------------------------------
#----------------------------------------------------------------------
def createAutodockConfigFile ():
	#6) Modifying docking parameters file
	with open ("ligand_protein.dpf") as parFile:
		parLines = parFile.readlines()[0:14]
	parLines.append ("epdb                            # **add** this to evaluate the small molecule")
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




#------------ main -------------
main ()
