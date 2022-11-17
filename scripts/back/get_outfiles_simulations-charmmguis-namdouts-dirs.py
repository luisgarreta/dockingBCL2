#!/usr/bin/python
USAGE="\
Get output files from compressed namd results in charmmgui directories.\n\
USAGE: get_outfiles_simulations.py <Ligands dir with namd-confXX.tgz files>"

import os, sys
import multiprocessing as mp

args      = sys.argv
args      = ["","charmmguis", "namdouts"]
inputDir  = args [1]
outputDir = args [2]
#namdsDir   = args [1]

def main ():
	namdsDir = extractSimulationFiles (inputDir)

	extractSimulationsLastComplex (namdsDir)

# Extract PSF PDB and DCDs
def extractSimulationFiles (inputDir):
	namdsDir = "namdouts"
	allLigands = os.listdir (inputDir)
	pool = mp.Pool ()
	pool.map (extractFiles, allLigands)

	os.system ("mkdir %s" % namdsDir)
	os.system ("mv namd-* %s" %  namdsDir)
	return (namdsDir)

def extractFiles (ligandDir):
	ligandPath = "%s/%s" % (inputDir, ligandDir)
	outFiles = ["step4_equilibration.dcd", "step5_1.dcd", "step3_input.psf", "step3_input.pdb"]
	namdFile  = "namd-%s" % ligandDir
	for file in outFiles:
		cmm = "tar -zxvf %s/%s.tgz %s/%s" % (ligandPath, namdFile, namdFile, file)
		print (">>>", cmm)
		os.system (cmm)



# Extract last protein and ligand structures
def extractSimulationsLastComplex (namdsDir):
	dirs = ["%s/%s" % (namdsDir, x) for x in os.listdir (namdsDir)]
	cwd = os.getcwd ()
	for namdDir in dirs:
		os.chdir (namdDir)
		cmmProt = "md-dcd-get-ProtLig-allFrames.tcl step3_input.psf step5_1.dcd"
		print (cmmProt)
		os.system (cmmProt)
		os.chdir (cwd)

#----------------------------------------------------------------------
#----------------------------------------------------------------------
main ()
