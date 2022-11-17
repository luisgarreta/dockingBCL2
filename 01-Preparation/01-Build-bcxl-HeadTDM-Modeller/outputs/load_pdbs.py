from pymol import cmd
import os, sys

files = [x for x in os.listdir () if ".pdb" in x]
i=1
for f in files:
    #pdb = "p%d" % i
    cmd.load (f)

