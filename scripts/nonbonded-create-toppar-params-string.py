#!/usr/bin/env python

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/usr/bin/python3
"""
Create parameters string for VMD namdenergy
"""
import os

strPar = ""
files = os.listdir ("toppar")
for f in files:
    strPar = "%s -par toppar/%s" % (strPar, f)

vmdCmm = 'namdenergy -nonb -sel [atomselect top "segname PROA or segname HETA"] %s ' % strPar

outf = open ("vmdenergy.tcl", "w")
outf.write ("package require nandenergy\n\n")
outf.write ("mol new step3_input.psf\n")
outf.write ("mol addfile step5_1.dcd first 0 last -1\n")
outf.write (vmdCmm)


