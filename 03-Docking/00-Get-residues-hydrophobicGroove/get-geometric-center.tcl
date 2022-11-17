#!/home/lg/.bin/xvmd

# Get the geometric center of an input molecule
puts "-----------------------------------------------------------------------------------------------"
set USAGE "get-geometric-center.tcl <PDB file>"
puts "-----------------------------------------------------------------------------------------------"

proc geom_center {selection} {
        # set the geometrical center to 0
        set gc [veczero]
        # [$selection get {x y z}] returns a list of {x y z} 
        #    values (one per atoms) so get each term one by one
        foreach coord [$selection get {x y z}] {
           # sum up the coordinates
           set gc [vecadd $gc $coord]
        }
        # and scale by the inverse of the number of atoms
        return [vecscale [expr 1.0 /[$selection num]] $gc]
}

set PROTEIN [lindex $argv 0]
mol new $PROTEIN type {pdb}
set sel [atomselect top "all"]

puts [format ">>>> %s" [geom_center $sel]]
exit

