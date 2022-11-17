#vmd -dispdev text -e wat_sphere.tcl
set PROTEIN [lindex $argv 0]
set ANGLE [expr [lindex $argv 1]]
puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
puts $PROTEIN
puts $ANGLE
puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
mol new $PROTEIN
set sel [atomselect top "all"]
set com [measure center $sel weight mass]
set matrix [transaxis z $ANGLE]
$sel moveby [vecscale -1.0 $com] 
$sel move $matrix
$sel writepdb bclxl_TMD_ZZ.pdb
quit
