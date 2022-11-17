# Get the system size and center of the system
mol new ../../MembBuilding/bclxl_assembly.psf
mol addfile ../../MembBuilding/bclxl_assembly.pdb

# Center of the system
set all [atomselect top all]
set CENTER [measure center $all]
puts "\n>>>>> System center: <<<<<" 
puts $CENTER
puts ">>>>>>>>>>><<<<<<<<<<<<<<<<<\n"

# Size of the system
set wat [atomselect top water]
set min [lindex [measure minmax $wat] 0]
set max [lindex [measure minmax $wat] 1]
set LENGTH [vecsub $max $min]
puts " '\n>>>>> System size: <<<<<" 
puts $LENGTH
puts ">>>>>>>>>>><<<<<<<<<<<<<<<<<\n"

quit

