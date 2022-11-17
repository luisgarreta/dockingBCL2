#!/usr/bin/env xvmd.py

# Calculate RMSDs for entire protein
# RMSD of trajectory frames: from frame0 to frames N
# Reference is frame 0
#
puts "--------------------------------------------------------------------------"
puts "--------------------------------------------------------------------------"
set PSF  [lindex $argv 0]
set DCD  [lindex $argv 1]
set PDB  [lindex $argv 2]
set OUT  [lindex $argv 3]

if {$PSF eq ""} then {
	puts "USAGE rmsd-trajectory.tcl <PSF file> <DCD trajectory> <PDB Reference> [Output name]"
	exit
}

# Output file name
set outName [format "%s-RMSD.csv" [lindex [split $DCD "_"] 0]]
if {$OUT ne ""} then {
	set outName $OUT
}
puts [format "Writing RMSDs into file: %s" $outName]
set outfile [open $outName w]

# Load data
mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1
mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0
mol new $PDB type {pdb} first 0 last -1 step 1 waitfor 1 

set nf [molinfo 0 get numframes]
puts [format "Number of frames: %d " $nf]

#set SELECTION "protein and backbone and noh and not (resid 227 to 231)" 
set SELECTION "protein and backbone and noh" 
set REFERENCE [atomselect 1 $SELECTION]
set sel [atomselect 0 $SELECTION]


# Calculate RMSD and write down results
puts $outfile "FRAME,RMSD" 
# rmsd calculation loop
for { set i 0 } { $i <= $nf } { incr i } {
	$sel frame $i
	$sel move [measure fit $sel $REFERENCE]
	puts $outfile [format "%s,%s" $i "[measure rmsd $sel $REFERENCE]"]
}
close $outfile

puts "--------------------------------------------------------------------------"
puts "--------------------------------------------------------------------------"
exit
