#!/opt/miniconda3/envs/biobb_env/bin/python
from pymol import cmd
PROTEIN = "inputs/1lxl_Protein_Model08.pdb"
HELIX   = "inputs/6f46_Helix8_OPM.pdb"

# Load helix 8 from 6f46 OPM Helix
cmd.load (HELIX, "helix8")

# Load protein from reconstructed 1lxl 
cmd.load (PROTEIN, "proteinBclxl")

cmd.super ("proteinBclxl", "helix8", object="superposition")
#cmd.save ("out_protein_helix_superposition.pdb")
cmd.save ("out_protein_aligned_OPM.pdb", "proteinBclxl")

