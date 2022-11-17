#!/usr/bin/env python3

import multiprocessing as mp
import os, sys

args = sys.argv
inputDir = args [1]
outputDir  = "pngs"
os.system ("mkdir pngs")

rgbs = os.listdir (inputDir)
def convertPNG (rgbFile):
    pngFile = rgbFile.split(".")[0] + ".png"
    cmm = "convert %s/%s %s/%s" % (inputDir, rgbFile, outputDir, pngFile)
    os.system (cmm)

pool = mp.Pool (maxtasksperchild=1)
pool.map (convertPNG, rgbs)
