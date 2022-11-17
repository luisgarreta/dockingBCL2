#!/opt/miniconda3/envs/biobb_env/bin/python

USAGE="\
Create complex protein + ligand from selected ligands poses. \
USAGE: create-complexes-charmmguy.py <Protein> <Ligands dir>"

import os, sys
from pymol import cmd

PROTEIN     = "inputs/protein.pdb"
LIGANDSDIR  = "inputs/ligands"                    # Dir with all ligands
LIGANDSSEL  = "inputs/selected_ligand_poses.txt"  # Names of selected ligands

ligandSelNames = [x.strip() for x in open (LIGANDSSEL).readlines ()]
protLines = open (PROTEIN).readlines ()

ligands = os.listdir (LIGANDSDIR)
for n, LIGAND in enumerate (ligands):
    conformation = LIGAND.split (".")[0]   # e.g. conf01_ad0001.pdb
    ligandName   = LIGAND.split ("_")[1].split(".")[0]  
    print (">>>", ligandName, conformation, ligandSelNames)
    if ligandName not in ligandSelNames:
        continue
    print (">>>", ligandName, conformation)

    #conformation = conformation.replace ("conf", "conformation")
    ligPath = "%s/%s" % (LIGANDSDIR, LIGAND)
    ligLines  = open (ligPath).readlines()

    for i in range (len (ligLines)):
        if "ATOM" in ligLines[i][0:4]:
            ligLines[i] = ligLines[i][:21] + "L" + ligLines[i][22:]

    number = conformation.split ("conf")[1].split("_")[0]
    complexPath = "complex%s_%s.pdb" % (number, ligandName)
    print (">>> ", complexPath)
    complexFile = open (complexPath, "w")
    complexFile.writelines (protLines)
    complexFile.writelines (ligLines)
    complexFile.close ()

    os.system ("mkdir %s" % conformation)
    os.system ("cp %s/%s %s" % (LIGANDSDIR, LIGAND, conformation)) 
    os.system ("cp %s %s" % (PROTEIN, conformation)) 
    os.system ("mv %s %s" % (complexPath, conformation)) 

