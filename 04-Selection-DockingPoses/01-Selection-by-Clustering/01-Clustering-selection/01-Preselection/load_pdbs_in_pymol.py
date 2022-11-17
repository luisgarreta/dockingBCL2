#!/usr/bin/python3

import sys, os
from pymol import cmd

# Open pymol and loads PDBs from input dir

args = sys.argv
pdbsDir = "ligands"

pdbs = sorted (["%s/%s" % (pdbsDir, x) for x in os.listdir(pdbsDir)])

for pdbFile in pdbs:
    print (pdbFile)
    cmd.load(pdbFile, pdbFile) # use el nombre de su archivo pdb # resto del código- bloquear
