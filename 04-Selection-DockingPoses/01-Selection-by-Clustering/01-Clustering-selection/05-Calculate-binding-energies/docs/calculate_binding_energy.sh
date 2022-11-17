#1) Preparing a protein
#prepare_receptor4.py -r protein.pdb 

#2) Preparing a ligand
#prepare_ligand4.py -l ligand.mol2 

#3) Generating a grid parameter file
#prepare_gpf4.py -l ligand.pdbqt -r protein.pdbqt -y

#4) Generating maps and grid data files
#autogrid4 -p protein.gpf

#5) Generating a docking parameter file
#prepare_dpf4.py -l ligand.pdbqt -r protein.pdbqt

#6) Running AutoDock
autodock4 -p ligand_protein.dpf -l scoring_result.log
