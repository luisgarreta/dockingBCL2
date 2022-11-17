mol new 6f46.pdb
set sel [atomselect top "all"]
set com [measure center $sel weight mass]
$sel moveby [vecscale -1.0 $com]

set matrix [transaxis z 90]
$sel move $matrix

$sel moveby $com
$sel writepdb rx.pdb
