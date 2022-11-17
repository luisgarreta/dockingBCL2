#!/bin/bash
echo "Loading local profile..."
	
PATHDOCK=/home/lg/BIO/omicas/simulations
MEEKO=$PATHDOCK/opt/meeko         # To prepare ligand
PYMOL=$PATHDOCK/opt/pymol         # Optimize and GridBox
VINA=$PATHDOCK/opt/vina           # Docking tool
WURLITZER=$PATHDOCK/opt/wurlitzer # To capture c++ output in notebooks

export PATH=$PATH:$PWD/bin

export PYTHONPATH=$MEEKO:$PYMOL:$VINA:$WURLITZER
