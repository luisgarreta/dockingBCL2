mol new 6f46.pdb
set sel [atomselect top "all"]
$sel moveby [vecinvert [measure center $sel weight mass]]
display resetview
$sel move [transaxis z -25]
$sel writepdb rz.pdb
