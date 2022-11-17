mol new 6f46.pdb
set sel [atomselect top "all"]
set com [measure center $sel weight mass]
set matrix [transaxis x 90]
$sel moveby [vecscale -1.0 $com]
$sel move $matrix
$sel moveby $com
$sel writepdb rx.pdb
