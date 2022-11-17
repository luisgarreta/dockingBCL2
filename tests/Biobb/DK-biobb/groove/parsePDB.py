#!/usr/bin/python3
from Bio.PDB import *
import sys

d3to1 = {'CYS': 'C', 'ASP': 'D', 'SER': 'S', 'GLN': 'Q', 'LYS': 'K',
'ILE': 'I', 'PRO': 'P', 'THR': 'T', 'PHE': 'F', 'ASN': 'N', 
'GLY': 'G', 'HIS': 'H', 'LEU': 'L', 'ARG': 'R', 'TRP': 'W', 
'ALA': 'A', 'VAL':'V', 'GLU': 'E', 'TYR': 'Y', 'MET': 'M'}


# Just an example input pdb
record = '2xa0.pdb'

# run parser
parser    = PDBParser(QUIET=True)
structure = parser.get_structure('struct', record)
chains    = strcture

# iterate each model, chain, and residue
# printing out the sequence for each chain
chainA = structure[0][0]
print (chainA)
sys.exit(0)

for model in structure:
    print (model)
    for chain in model:
        print (chain)
        seq = []
        for residue in chain:

            print (">>>", residue)
            seq.append(d3to1[residue.resname])
            print('>some_header\n',''.join(seq))
