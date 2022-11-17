#!/usr/bin/python3

# Get atoms location of residues from Bcl-xl helices 
# INPUTS:
#  - 1lxl Helices file from PDB
#  - 1lxl aminos sequence (fasta)
#  - Starting position PDB aminos
#  - Prepared bcl-xl system (PDB file: 1lxl + 6f46)

import os, sys

args        = sys.argv
args        = ["","inputs/1lxl_helices.pdb", 
               "inputs/1lxl.fasta", -3, "inputs/protein.pdb"]
helicesFile = args [1]
fastaFile   = args [2]
startPos    = args [3]
pdbFile     = args [4]

#--------------------------------------------------------
# Get the las ATOM from PDB amino code and amino position
def getAtomsResidue (aminoCode, aminoPos, pdbLines, flag):
    n = len (pdbLines)
    atomLines = []
    if (flag == "all"):
        for line in pdbLines:
            elems = line.split ()
            if ("ATOM"==elems [0] and aminoCode==elems[3] and str(aminoPos)==elems[5]):
                atomLines.append (line)
    elif (flag == "last"):
        while (n>0):
            n -= 1
            line = pdbLines [n]
            elems = line.split ()
            if ("ATOM"==elems [0] and aminoCode==elems[3] and str(aminoPos)==elems[5]):
                return (line.strip())
    return (atomLines)
#--------------------------------------------------------

aminosTable = {'C':'CYS','D':'ASP','S':'SER','Q':'GLN','K':'LYS','I':'ILE','P':'PRO',
      'T':'THR','F':'PHE','N':'ASN','G':'GLY','H':'HIS','L':'LEU','R':'ARG',
      'W':'TRP','A':'ALA','V':'VAL','E':'GLU','Y':'TYR','M':'MET'}


#--------------------------------------------------------------------
# According to Lee2019, hydrophobic groove 
# is formed mainly by helices 3,4, and 5
def getGrooveHelices (helicesFile):
    # Load helices for Bcl-xl protein
    helixLines = open (helicesFile).readlines()   # Helices 2 to  7
    helices    = {}
    nHelix     = 1
    for l in helixLines:
        helices [nHelix] = l.strip()
        nHelix += 1

    helicesGroove = {}
    helicesGroove [3] = helices [3]
    helicesGroove [4] = helices [4]
    helicesGroove [5] = helices [5]

    print (">>> Groove helices from PDB file:")
    for h in helices:
        print (h, helices[h])

    return (helices)
#--------------------------------------------------------------------

helicesGroove = getGrooveHelices (helicesFile)

print (">>> Amino acid sequence PDB 1lxl")
sequence = open (fastaFile).readlines ()[1]
sequence = sequence [4:]
print (sequence)

print (">>> Amino acids name and number:")
atomsFile = open ("groove-atoms-residues.pdb", "w")
pdbLines = open (pdbFile).readlines()
for h in helicesGroove:
    helix    = helicesGroove [h]
    elems    = helix.split ()
    ini, end = int (elems [5]), int (elems [8])
    aminos   = sequence [(ini-1):end]   ## All aminos
    print (">>> Helix ", h, ":", ini, end, aminos)

    for a in aminos:
        atomLines = getAtomsResidue (aminosTable[a], ini, pdbLines, "all")
        [print (x.strip()) for x in atomLines]
        atomsFile.writelines (atomLines)
        ini+=1

