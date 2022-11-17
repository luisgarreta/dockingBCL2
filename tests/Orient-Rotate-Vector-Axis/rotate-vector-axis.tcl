set PROTEIN [lindex $argv 0]
mol new $PROTEIN
set sel [atomselect top all]
set M [transvecinv {-1 3 5}]
$sel move $M
set M [transaxis y -90]
$sel move $M
$sel writepdb out_longaxis.pdb
