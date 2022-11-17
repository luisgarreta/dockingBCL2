#!/usr/bin/python3
# Split full docking PDB file into individual ligand PDBs

import os, sys
args = sys.argv

pdbsFile    = "clusters.dock4.pdb"
outDirAll   = "pdbsAll"
outDirHeads = "pdbsHeads"

lines    = open (pdbsFile).readlines()

n = len (lines)
i = 0
clusPrevious = -1
while (i < n-1):
    HEADCLUSTER = True
    name = "dock.pdb"
    pdbFile = open (name, "w")
    line = lines [i]
    while ("TER" not in line):
        pdbFile.write (line)
        if ("Cluster:" in line):
            cluster = int (line.split()[2])
        if ("ClusterRank:" in line):
            clusterRank = int (line.split()[2])
        i+=1
        line = lines [i]

    pdbFile.write (line)
    pdbFile.close()
    pdbName = "%s/sw%.2d%.2d.pdb" % (outDirAll, cluster, clusterRank)
    os.system ("mv %s %s" % (name, pdbName))
    if (cluster != clusPrevious):
        os.system ("cp %s %s" % (pdbName, outDirHeads))
        clusPrevious = cluster

    i += 1
            

