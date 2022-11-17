#!/opt/miniconda3/envs/biobb_env/bin/python
from pymol import cmd

# Select helix 8 from 6f46 Helix
cmd.load ("6f46.pdb", "helix")
cmd.select ("helix8", "resid 209-331")
cmd.save ("out_helix.pdb", "helix8")

cmd.reinitialize()
# Select loop helix 8 from 1lxl
cmd.load ("1lxl.pdb", "bcl")
cmd.select ("loop8", "resid 209-217")
cmd.save ("out_loop.pdb", "loop8")

cmd.reinitialize ()
cmd.load ("out_loop.pdb", "loop8") 
cmd.load ("out_helix.pdb", "helix8") 
cmd.super ("helix8", "loop8", object="hl8")
cmd.save ("out_hl.pdb")
cmd.save ("out_helix8_superposed.pdb", "helix8")

