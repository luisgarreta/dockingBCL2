#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/opt/miniconda3/envs/prolif/bin/python

USAGE="\
Calculate interaction energies protein-ligand from DCDs trajectories.\n\
USAGE : interaction-energies.py <PSF topology file> <DCD trajectory file>\n\
"
import os, sys
import MDAnalysis as mda
import prolif as plf         # Package for calculating interaction energies 
import pandas as pd

args = sys.argv
#args = ["", "step5_input.psf", "step7-DCDs.dcd"]

if (len (args) < 3):
    print (USAGE)
    sys.exit (0)

PSFFILE = args [1]
DCDFILE = args [2]
OUTFILE = args [3] if (len (args) > 3) else "interactions.csv"

u = mda.Universe(PSFFILE, DCDFILE)

# guess missing info
elements = mda.topology.guessers.guess_types(u.atoms.names)
u.add_TopologyAttr('elements', elements)

lig  = u.atoms.select_atoms("segid HETA")
prot = u.atoms.select_atoms("segid PROA")

lmol = plf.Molecule.from_mda(lig)
pmol = plf.Molecule.from_mda(prot)

#---- Everything looks good, we can now compute a fingerprint:
fp = plf.Fingerprint()

#fp = plf.Fingerprint(["HBDonor", "HBAcceptor"])

#fp.run(u.trajectory[:10], lig, prot)
fp.run(u.trajectory, lig, prot)

# drop the ligand residue column since there's only a single ligand residue
df = fp.to_dataframe()

df = df.droplevel("ligand", axis=1)
df.to_csv (OUTFILE.split(".")[0] + "-WIDE.csv")

data = df.reset_index()
data = pd.melt(data, id_vars=["Frame"], var_name=["residue","interaction"])
data = data[data["value"] != False]
data.reset_index(inplace=True, drop=True)
data.columns = ["FRAME", "RESIDUE", "INTERACTION", "VALUE"]
data.to_csv (OUTFILE.split (".")[0] + "-LONG.csv", index=False)

