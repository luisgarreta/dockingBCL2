#!/usr/bin/env python3

from pymol import *
import draw_rotation_axis as dr
import centroid as ct

def printCenters ():
    print ("Centers of masses:")
    print (cmd.centerofmass ("wa"))
    print (cmd.centerofmass ("wb"))
    print (cmd.centerofmass ("wc"))
    print ("")

def printMatrix (t):
    print (">>> Transformation matrix:")
    n = 3
    t = [round (x, 3) for x in t]
    print ("%10s %10s %10s %10s" % (t[0], t[4], t[8], t[12]))
    print ("%10s %10s %10s %10s" % (t[1], t[5], t[9], t[12]))
    print ("%10s %10s %10s %10s" % (t[2], t[6], t[10], t[14]))
    print ("%10s %10s %10s %10s" % (t[3], t[7], t[11], t[15]))
    print("\n")

cmd.load ("2vak.pdb")
cmd.select ("cha", "chain A")
cmd.select ("chb", "chain B")
cmd.select ("chc", "chain C")

cmd.create ("wa", "cha")
cmd.create ("wb", "chb")
cmd.create ("wc", "chc")

printCenters ()

cmd.super ("wa", "chb")
t = cmd.get_object_matrix ("wa")
printMatrix (t)
printCenters ()

cmd.super ("wa", "chc")
t = cmd.get_object_matrix ("wa")
printMatrix (t)
printCenters()

cmd.super ("wa", "cha")
t = cmd.get_object_matrix ("wa")
printMatrix (t)
printCenters()
