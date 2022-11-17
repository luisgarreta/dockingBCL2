#!/usr/bin/env xvmd.py

# Extracts the protein and ligand PDB files from each step.
#
puts "-----------------------------------------------------------------------------------------------"
set USAGE "
Extracts the protein and ligand PDB files from each step.
frame-trajectory.tcl <PSF file> <DCD trajectory>" 
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
	set DIRNAME [format "frame%.5d" $i] 
	mkdir $DIRNAME
	cd $DIRNAME
	set frame0 [atomselect top "segname PROA" frame $i]
	set OUTNAME [format "frame%.5d-protein.pdb" $i];
	$frame0 writepdb $OUTNAME
	set frame0 [atomselect top "segname HETA" frame $i]
	set OUTNAME [format "frame%.5d-ligand.pdb" $i];
	$frame0 writepdb $OUTNAME
	cd ".."
}

exit

