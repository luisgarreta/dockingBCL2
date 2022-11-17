#!/home/lg/.bin/xvmd
# Get frame from trajectory
#
puts "-------------------------------------------------------------------------"
set USAGE "get-frame.tcl <PSF file> <DCD trajectory> <Frame number> \[protein|all]"

set PSF  [lindex $argv 0]
set DCD  [lindex $argv 1]
set FRAME [lindex $argv 2]
set SELECTION [lindex $argv 3]   

if {$PSF eq ""} then {
	puts $USAGE
	exit
}

set SELECTION "all"
if {$SEL eq "protein"} then {
	set SELECTION "protein and backbone and noh"
}

mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1
mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0

#set frame0 [atomselect top "protein and backbone and noh" frame $FRAME]
set frame0 [atomselect top $SELECTION frame $FRAME]
$frame0 writepdb f$FRAME.pdb
exit

