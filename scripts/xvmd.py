#!/usr/bin/env python3

#!/usr/bin/python3

# Execute tcl scripts in vmd with or without arguments

import os, sys
args = sys.argv

SCRIPT = args [1]
ARGS   = args [2:]

cmm = "vmd -dispdev text -e %s" % SCRIPT
cmm = "%s -args %s" % (cmm, (" ".join (ARGS)))

if (len(args) < 3):
    cmm = "tclsh %s" % SCRIPT
    
os.system (cmm)

