mol new bclxl_TMD.pdb
set sel [atomselect top "all"]
$sel moveby [vecinvert [measure center $sel weight mass]]
display resetview
$sel move [transaxis z -125]
$sel writepdb bclxl_TMD_Z_125.pdb
quit
