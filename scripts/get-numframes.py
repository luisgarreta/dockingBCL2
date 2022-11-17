#!/usr/bin/env python3
import sys
import subprocess 

""" Get the number of frames of a DCD trajectory file"""

args= sys.argv

dcdFile = args [1]

result = subprocess.run (["catdcd", "-num", dcdFile], capture_output=True, encoding='UTF-8')

resultsLines = result.stdout.split("\n")
for line in resultsLines:
    if "Total frames:" in line:
        num = int (line.split (":")[1])
        break
print (num)
