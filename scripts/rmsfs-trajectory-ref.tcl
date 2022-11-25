#!/usr/bin/env xvmd.py

# Aligning trajectories based on an atom selection and 
# calculate RMSF of alpha carbons

puts "--------------------------------------------------------------------"
puts "--------------------------------------------------------------------"
set PSF [lindex $argv 0];
set DCD [lindex $argv 1];
set PDB [lindex $argv 2];
set TYPE [lindex $argv 3]
set OUT [format "%s-RMSF.csv" [lindex [split $DCD "."] 0]]
if { $argc == 6 } then {
	set OUT  [lindex $argv 4];list
}

mol new     $PSF type {psf} first 0 last -1 step 1 waitfor 1
mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0
mol new     $PDB type {pdb} first 0 last -1 step 1 waitfor 1 

set SELECTION "segid PROA and name CA"
if {$TYPE eq "GROOVE"} then {
	set SELECTION "segname PROA and name CA and noh and resid 104 to 132" 
}
if {$TYPE eq "HEAD"} then {
	set SELECTION "segname PROA and name CA and noh and (resid 1 to 22 or resid 83 to 195)" 
}

set ref [atomselect 1 $SELECTION]
set sel [atomselect 0 $SELECTION]

for { set f 0 } { $f < [molinfo 0 get numframes] } { incr f } {
	$sel frame $f
	$sel move [measure fit $sel $ref]
}

$sel delete
$ref delete

# Calculate RMSF and write to file
set outfile [open $OUT w]
puts $outfile "RESID, RMSF"
set sel [atomselect 0 $SELECTION]
set val [measure rmsf $sel]
for {set i 0} {$i < [llength $val]} { incr i} {
    puts $outfile [format "%s, %s" $i [lindex $val $i]]
}
$sel delete
close $outfile

exit

