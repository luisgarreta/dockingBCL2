#!/usr/bin/python3

# Cluster ligands from dir with PDBs files

import os
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from pymol import cmd                                   # We will use pymol for comparison
from scipy.cluster.hierarchy import dendrogram, linkage # All we need for clustering

# Loading the poses
NCLUSTERS = 10
pdbsDir = "pdbs"
poses = os.listdir (pdbsDir)
n     = len (poses)
hmap  = np.zeros (shape = (n, n)) - 1
table = pd.DataFrame ()

for i, mol in enumerate (poses):
    for j, jmol in enumerate (poses):
        if (hmap[i,j] != -1):
            continue
        else:
            cmd.load ("%s/%s" % (pdbsDir, mol), "ref")
            cmd.load ("%s/%s" % (pdbsDir, jmol), "target")
            rmsd = cmd.rms_cur ("ref", "target", cycles=10, matchmaker=1)
            cmd.deselect ()
            cmd.delete ("all")
            hmap [i,j] = rmsd
            hmap [j,i] = rmsd
            table.loc [mol, jmol] = rmsd
            table.loc [jmol, mol] = rmsd

# Write RMSDs matrix
table.to_csv ("out_clusters_rmsds.csv")

# Clustering
linked = linkage (hmap, "complete")

from sklearn.cluster import AgglomerativeClustering
cluster = AgglomerativeClustering(n_clusters=NCLUSTERS, affinity='euclidean', linkage='ward')
cl = cluster.fit_predict(table)

print (cl)

clusDic = {}
for i in range (NCLUSTERS):
    clusDic [i] = []

for i,c in enumerate (cl):
    clusDic[c].append (table.index [i])

groupsFile   = open ("out_clusters_groups.out", "w")
pdbsFile     = open ("out_clusters_pdbs.out", "w")
pdbsFileHead = open ("out_clusters_pdbs_heads.out", "w")
for c in clusDic:
    line = "%s:%s\n" % (c, ",".join (clusDic[c]))
    groupsFile.write (line)

    ISHEAD = True
    for pdb in clusDic [c]:
        print (">>>", pdb)
        pdbLines = open ("%s/%s" % (pdbsDir, pdb), "r").readlines()
        pdbsFile.writelines (pdbLines)
        if (ISHEAD):
            pdbsFileHead.writelines (pdbLines)
            ISHEAD = False
            
groupsFile.close()
pdbsFile.close()
pdbsFileHead.close()
            
print (clusDic)

# Plot 
#plt.figure(figsize=(50, 10))
#plt.title('Hierarchical Clustering Dendrogram')
#plt.xlabel('sample index')
#plt.ylabel('distance')
#dendrogram(linked, leaf_rotation=90., leaf_font_size=8.,)
#plt.show()


