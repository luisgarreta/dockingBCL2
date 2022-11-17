#!/home/lg/.bin/xvmd
# Get frame from trajectory
#
puts "-----------------------------------------------------------------------------------------------"
set USAGE "md-dcd-get-ProtLig-allFrames.tcl <PSF file> <DCD trajectory>" 
puts "-----------------------------------------------------------------------------------------------"

set PSF  [lindex $argv 0];
set DCD  [lindex $argv 1];

if {$PSF eq "" || $DCD eq ""} then {
	puts $USAGE
	exit
}

set id [mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1]
mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0

set nFrames [molinfo $id get numframes]
puts ">>> nFrames: $nFrames"

for {set i 0} {$i < $nFrames} {incr i} {
	set DIRNAME [format "frame%.2d" $i] 
	mkdir $DIRNAME
	cd $DIRNAME
	set frame0 [atomselect top "protein" frame $i]
	set OUTNAME [format "frame%.2d-protein.pdb" $i];
	$frame0 writepdb $OUTNAME
	set frame0 [atomselect top "segname HETA" frame $i]
	set OUTNAME [format "frame%.2d-ligand.pdb" $i];
	$frame0 writepdb $OUTNAME
	cd ".."
}

exit

