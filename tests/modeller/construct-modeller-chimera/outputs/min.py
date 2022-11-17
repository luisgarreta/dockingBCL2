from pymol import cmd

cmd.load ("a.pdb")

cmd.minimize(sele="a", iter=500, interval=50)
