#!/usr/bin/env xvmd.py

#!/home/lg/.bin/xvmd
#!/users/legarreta/bin/xvmd
#
set PSFFILE [lindex $argv 0];
set DCDFILE [lindex $argv 1];
set TYPE [lindex $argv 2]
set OUTFILE "radio-gyration.csv"
if { $argc == 5 } then {
	set OUTFILE  [lindex $argv 3];list
}

mol new $PSFFILE first 0 last -1
mol addfile $DCDFILE first 0 last -1 step 1 waitfor -1 0

#----------------------------------------------------------------
proc gyr_radius {sel} {
  # make sure this is a proper selection and has atoms
  if {[$sel num] <= 0} {
    error "gyr_radius: must have at least one atom in selection"
  }
  # gyration is sqrt( sum((r(i) - r(center_of_mass))^2) / N)
  set com [center_of_mass $sel]
  set sum 0
  foreach coord [$sel get {x y z}] {
    set sum [vecadd $sum [veclength2 [vecsub $coord $com]]]
  }
  return [expr sqrt($sum / ([$sel num] + 0.0))]
}
#----------------------------------------------------------------
proc center_of_mass {selection} {
	# some error checking
	if {[$selection num] <= 0} {
		error "center_of_mass: needs a selection with atoms"
	}
	# set the center of mass to 0
	set com [veczero]
	# set the total mass to 0
	set mass 0
	# [$selection get {x y z}] returns the coordinates {x y z} 
	# [$selection get {mass}] returns the masses
	# so the following says "for each pair of {coordinates} and masses,
		#  do the computation ..."
	foreach coord [$selection get {x y z}] m [$selection get mass] {
	   # sum of the masses
	   set mass [expr $mass + $m]
	   # sum up the product of mass and coordinate
	   set com [vecadd $com [vecscale $m $coord]]
	}
	# and scale by the inverse of the number of atoms
	if {$mass == 0} {
		error "center_of_mass: total mass is zero"
	}
	# The "1.0" can't be "1", since otherwise integer division is done
	return [vecscale [expr 1.0/$mass] $com]
}
#----------------------------------------------------------------

set outfile [open $OUTFILE w]
#puts $outfile "FRAME, PROTEIN, COMPLEX"
puts $outfile "FRAME, RADIUSG"
set nf [molinfo top get numframes] 
set i 0

# Set selection according to TYPE
set SELECTION "segname PROA and name CA and noh"
if {$TYPE eq "Groove"} then {
	set SELECTION "segname PROA and name CA and noh and resid 104 to 132" 
}
if {$TYPE eq "HEAD"} then {
	set SELECTION "segname PROA and name CA and noh and (resid 1 to 22 or resid 83 to 195)" 
}
if {$TYPE eq "NOFLD"} then {
	set SELECTION "segname PROA and name CA and noh and not resid 21 to 84" 
}
if {$TYPE eq "noLOOPs"} then {
	set SELECTION "segname PROA and name CA and noh and not resid 21 to 84 and not resid 195 to 206" 
}

set PROTEIN [atomselect top $SELECTION] 
#set COMPLEX [atomselect top "segname PROA or segname HETA"] 
while {$i < $nf} {
    $PROTEIN frame $i
    $PROTEIN update

    #$COMPLEX frame $i
    #$COMPLEX update

    set i [expr {$i + 1}]
    set rogProtein [gyr_radius $PROTEIN]
    puts $outfile "$i, $rogProtein"
    #set rogComplex [gyr_radius $COMPLEX]
    #puts $outfile "$i, $rogProtein, $rogComplex"
} 

close $outfile
exit
