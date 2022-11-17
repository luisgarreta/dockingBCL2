#!/opt/miniconda3/envs/biobb_env/bin/python
"""
Orient target protein to reference protein.
Used to orient Bcl protein to OPM helix.
"""

import sys
args = sys.argv

from pymol import cmd
PROTEIN = args [1] # "protein.pdb"
TARGET   = args [2] # "6f46_Helix8_OPM.pdb"

# Load helix 8 from 6f46 OPM Helix
cmd.load (TARGET, "helix8")

# Load protein from reconstructed 1lxl 
cmd.load (PROTEIN, "proteinBclxl")

cmd.super ("proteinBclxl", "helix8", object="superposition")
#cmd.save ("out_protein_helix_superposition.pdb")
cmd.save ("out_protein_aligned_OPM.pdb", "proteinBclxl")

