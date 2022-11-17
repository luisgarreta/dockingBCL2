RECEPTOR_PDB=$1
RECNAME=`echo $RECEPTOR_PDB|cut -d"." -f1`
LIGAND_SDF=$2
LIGNAME=`echo $LIGAND_SDF|cut -d"." -f1`
echo "-----------------------------------------------------"
echo ">>>> Preparing receptor <<<<<"
echo "-----------------------------------------------------"
#prepare_receptor4.py -A hydrogens -U nphs 
prepare_receptor4.py -l $RECEPTOR_SDF -o $RECNAME -v 


echo ""
echo "-----------------------------------------------------"
echo ">>>> Preparing ligand <<<<<"
echo "-----------------------------------------------------"
prepare_ligand4.py -l $LIGAND_SDF -o $LIGNAME -v 




