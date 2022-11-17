#!/home/lg/.bin/xvmd
set PROTEIN bclxl_MAIN.pdb
mol new $PROTEIN
set sel [atomselect top all]
$sel move {{1.0 0.0 0.0 0.0} 
	       {0.0 1.0 0.0 0.0}
           {0.0 0.0 1.0 100.0} 
		   {0.0 0.0 0.0 1.0}}
$sel writepdb bclxl_MAIN_Z.pdb
cp bclxl_MAIN_Z.pdb quimera
quit
