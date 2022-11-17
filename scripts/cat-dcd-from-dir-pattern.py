#!/usr/bin/python3
USAGE="\
Cat trajectory DCD files from input dir and file pattern string\n\
USAGE: cat-dcd-from-dir-pattern.py <input dir> <file pattern>"

import os, sys

args = sys.argv

inputDir    = args [1]
filePattern = args [2]

dcdFiles = [ x for x in os.listdir (inputDir) if ".dcd" in x]
dcdFiles = sorted ([ x for x in dcdFiles if filePattern in x])
dcdFiles = ["%s/%s" % (inputDir, x) for x in dcdFiles]

stringFiles = " ".join (dcdFiles)
cmm = "catdcd -o %s-DCDs.dcd %s" % (filePattern, stringFiles)

print (cmm)
os.system (cmm)
