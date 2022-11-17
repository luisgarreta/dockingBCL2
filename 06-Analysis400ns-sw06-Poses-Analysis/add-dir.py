#!/usr/bin/env python
import os, sys

dirs = sorted ([x for x in os.listdir (".") if x[2]=="-"], reverse=True)
for d in dirs:
    num  = int (d.split("-")[0])
    name = d.split("-", 1)[1]

    newName = "%.2d-%s" % (num+1, name)
    cmm = "mv %s %s" % (d, newName)
    print (cmm)
