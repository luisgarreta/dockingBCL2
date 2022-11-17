#!/opt/miniconda3/envs/biobb_env/bin/python

USAGE="\
Create complex protein + ligand from selected ligands poses. \
USAGE: create-complexes-charmmguy.py <Protein> <Ligands dir>"

import os, sys
from pymol import cmd

PROTEIN     = "protein.pdb"
LIGANDSDIR  = "selected"                    # Dir with all ligands
protLines   = open (PROTEIN).readlines ()

ligands = os.listdir (LIGANDSDIR)
for lig in ligands:
    ligPath   = "%s/%s" %(LIGANDSDIR, lig)  
    ligLines  = open (ligPath).readlines()
    for i in range (len (ligLines)):
        if "ATOM" in ligLines[i][0:4]:
            ligLines[i] = ligLines[i][:21] + "L" + ligLines[i][22:]

    ligname = lig.split (".")[0]
    os.system ("mkdir complex_%s" % ligname)

    complexPath = "complex_%s/complex_%s.pdb" % (ligname, ligname)
    print (">>> ", complexPath)
    complexFile = open (complexPath, "w")
    complexFile.writelines (protLines)
    complexFile.writelines (ligLines)
    complexFile.close ()

    os.system ("cp %s %s" % (PROTEIN, ligname)) 

