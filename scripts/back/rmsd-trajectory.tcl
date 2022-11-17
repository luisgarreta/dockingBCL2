#!/home/lg/.bin/xvmd

# Calculate RMSDs for entire protein
# RMSD of trajectory frames: from frame0 to frames N
# Reference is frame 0
#
puts "--------------------------------------------------------------------------"
puts "--------------------------------------------------------------------------"
set PSF  [lindex $argv 0]
set DCD  [lindex $argv 1]
set OUT  [lindex $argv 2]

if {$PSF eq ""} then {
	puts "USAGE rmsd-trajectory.tcl <PSF file> <DCD trajectory>"
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

set nf [molinfo top get numframes]
puts [format "Number of frames: %d " $nf]

#set SELECTION "protein and backbone and noh and not (resid 227 to 231)" 
set SELECTION "protein and backbone and noh" 
set frame0 [atomselect top $SELECTION frame 0]
set sel [atomselect top $SELECTION]

# Calculate RMSD and write down results
puts $outfile "TIME,RMSD" 
# rmsd calculation loop
for { set i 1 } { $i <= $nf } { incr i } {
	$sel frame $i
	$sel move [measure fit $sel $frame0]
	puts $outfile [format "%s,%s" $i "[measure rmsd $sel $frame0]"]
}
close $outfile

puts "--------------------------------------------------------------------------"
puts "--------------------------------------------------------------------------"
exit
