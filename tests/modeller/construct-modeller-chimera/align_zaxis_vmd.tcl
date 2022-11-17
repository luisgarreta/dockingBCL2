#vmd -dispdev text -e wat_sphere.tcl
set PROTEIN [lindex $argv 0]
set DISTANCE [expr [lindex $argv 1]]
puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
puts $PROTEIN
puts $DISTANCE
puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
mol new $PROTEIN
set sel [atomselect top "all"]
$sel moveby [vecinvert [measure center $sel weight mass]]
display resetview
$sel move [transaxis z $DISTANCE]
$sel writepdb bclxl_TMD_Z.pdb
quit
