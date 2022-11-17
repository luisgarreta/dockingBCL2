#!/usr/bin/python3
USAGE="\
Create free binding energies table from log file in each ligand results dir.\n\
USAGE: create_binding_energies_table.py"

import os, sys
args = sys.argv
#args = ["", "frames"]

energiesDirName = args [1]

#--------------------------------------------------------------------
#--------------------------------------------------------------------
def main ():
	energiesPaths = ["%s/%s" % (energiesDirName, x) for x in os.listdir (energiesDirName)]

	# Create a file with ligand name in each ligand dir
	for path in energiesPaths:
		os.system ("echo %s > %s/ligand.name" % (path.split("-")[-1], path))

	energiesList = ["Conformation, LigandName, Frame, AD_BindingEnergy,VN_BindingEnergy, Average_Energy"]
	for dir in energiesPaths:
		print (">>> Dir:", dir)
		ligAndEnergies = getBindingEnergy (dir)
		energiesList.append (ligAndEnergies)

	energiesLines = "\n".join (energiesList)+"\n"
	energiesTable = "Binding_Energies_Table_FULL.csv"
	open (energiesTable, "w").writelines (energiesLines)
	cmm = "average_binding_energies_table.R %s" % energiesTable
	os.system (cmm)

#--------------------------------------------------------------------
#--------------------------------------------------------------------
def getBindingEnergy (dir):
	ligName = open ("%s/%s" % (dir, "ligand.name")).read ().strip()

	framesDirs = ["%s/%s" % (dir, x) for x in os.listdir (dir) if "frame" in x]
	energies = []
	for framedir in framesDirs:
		print (">>> Framedir:", framedir)
		autodockLines = open ("%s/%s" % (framedir, "out_energies_autodock.log")).readlines ()
		for line in autodockLines:
			if ("Estimated Free Energy" in line):
				autodockEnergy = float (line.split ()[8])
				break

		vinaLines = open ("%s/%s" % (framedir, "out_energies_vina.log")).readlines ()
		for line in vinaLines:
			if ("Affinity" in line):
				vinaEnergy = float (line.split ()[1])
				break

		avrEnergy = round ((autodockEnergy + vinaEnergy)/2, 3)
		energies.append ([os.path.basename (framedir),autodockEnergy, vinaEnergy, avrEnergy])
	
	valuesList = []
	for values in energies:
		print (">>>", values)
		ligAndEnergies = "%s,%s,%s,%s,%s,%s" % (os.path.basename (dir), ligName, values[0], values[1], values[2], values[3])
		valuesList.append (ligAndEnergies)
	return ("\n".join (valuesList))

#--------------------------------------------------------------------
#--------------------------------------------------------------------
def copyLigandNamesToFiles (ligandsDirName, energiesPaths):
	# Create dic with ligand names
	ligandsDic = {}
	ligandNames = os.listdir (ligandsDirName)
	for name in ligandNames:
		conf = name.split ("_")[0]
		lign = name.split ("_")[1].split(".")[0]
		ligandsDic [conf] = lign

	for path in energiesPaths:
		conf = os.path.basename (path)
		open ("%s/ligand.name" % path, "w").write (ligandsDic [conf])


#--------------------------------------------------------------------
#--------------------------------------------------------------------
main()
