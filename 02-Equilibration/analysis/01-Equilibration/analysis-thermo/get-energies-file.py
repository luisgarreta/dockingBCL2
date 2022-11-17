#!/usr/bin/python3
# Get and save energies from namd out file 

import os, sys

args = sys.argv
logfile = args [1]
prefix  = logfile.split("_")[0]
lines = open (logfile).readlines()
outfile = open ("%s_energies.csv" % prefix, "w")

FIRST = True
for l in lines:
    lst = l.split()
    if (lst==[]):
        continue

    # Headers
    if (lst[0]=="ETITLE:" and FIRST==True): 
        outfile.write(",".join(lst[1:]))
        FIRST = False
        outfile.write("\n")

    # Energies data
    if (lst[0]=="ENERGY:"):
        outfile.write(",".join(lst[1:]))
        outfile.write("\n")


outfile.close()
